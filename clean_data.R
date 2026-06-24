library(arrow)
library(dplyr)
library(tidyr)
library(lubridate)

# Input and Output file paths
# Input: the harmonized DB produced by the data pipeline (sibling repo).
# Output: the FRESHWATER-focused cleaned dataset this paper is built from.
input_file <- "../../pipeline/data/harmonized/harmonized.feather"
output_file <- "fecal_indicators_clean.feather"

cat("Opening input feather database...\n")
tab <- read_feather(input_file, as_data_frame = FALSE)
n_original <- nrow(tab)
cat("Original rows:", n_original, "\n\n")

# Define US States/Territories for country standardization
us_states <- c(
  "California", "Florida", "New Jersey", "Minnesota", "Virginia", "Georgia", 
  "New York", "South Carolina", "Oregon", "Utah", "Wisconsin", "Kansas", 
  "Missouri", "North Carolina", "Washington", "Michigan", "Iowa", "South Dakota", 
  "Texas", "Pennsylvania", "New Hampshire", "Alabama", "North Dakota", 
  "Louisiana", "Colorado", "Illinois", "Arkansas", "Ohio", "Connecticut", 
  "Puerto Rico", "Massachusetts", "Oklahoma", "Maryland", "Idaho", "Mississippi", 
  "New Mexico", "Montana", "West Virginia", "District of Columbia", "Arizona", 
  "Nevada", "Wyoming", "Kentucky", "Tennessee", "Vermont", "Alaska", "Indiana", 
  "Maine", "Delaware", "Virgin Islands", "Rhode Island", "Hawaii", "Guam", 
  "American Samoa", "N. Mariana Islands", "Northern Mariana Islands", "USA",
  "United States of America (the)", "Nebraska"
)

cat("Running diagnostics to count rows that violate cleaning rules...\n")
# We will use Arrow dplyr to compute counts of invalid rows
qc_counts <- tab %>%
  summarise(
    invalid_var = sum(
      !(tolower(var) %in% c(
        "escherichia coli", "escherichia", 
        "fecal coliform", "fecal coliforms", 
        "total coliform", "total coliforms", 
        "intestinal enterococci", 
        "fecal streptococcus group bacteria"
      ))
    ),
    invalid_date = sum(date < as.Date("1950-01-01") | date > as.Date("2026-12-31")),
    invalid_lat = sum(lat < -90 | lat > 90),
    invalid_lon = sum(lon < -180 | lon > 180),
    null_island = sum(lat == 0 & lon == 0),
    negative_val = sum(val < 0),
    extreme_val = sum(val > 1e7)
  ) %>%
  collect()

print(qc_counts)
cat("\n")

cat("Applying cleaning and standardization filters...\n")
# Build the pipeline
clean_tab <- tab %>%
  # 1. Focus on the specified variables (case-insensitive)
  mutate(
    var_clean = case_when(
      tolower(var) %in% c("escherichia coli", "escherichia") ~ "Escherichia coli",
      tolower(var) %in% c("fecal coliform", "fecal coliforms") ~ "Fecal Coliform",
      tolower(var) %in% c("total coliform", "total coliforms") ~ "Total Coliform",
      tolower(var) == "intestinal enterococci" ~ "Intestinal enterococci",
      tolower(var) == "fecal streptococcus group bacteria" ~ "Fecal Streptococcus Group Bacteria",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(var_clean)) %>%
  
  # 2. Filter nonsensical dates
  filter(date >= as.Date("1950-01-01") & date <= as.Date("2026-12-31")) %>%
  
  # 3. Filter nonsensical coordinates
  filter(lat >= -90 & lat <= 90) %>%
  filter(lon >= -180 & lon <= 180) %>%
  filter(!(lat == 0 & lon == 0)) %>%
  
  # 4. Filter nonsensical values (negative and extreme outliers)
  filter(val >= 0 & val <= 1e7) %>%
  
  # 5. Standardize country name
  mutate(
    country = case_when(
      state %in% us_states ~ "United States",
      state %in% c("England", "United_kingdom") ~ "United Kingdom",
      state %in% c("Mexico", "México", "Hidalgo", "Tabasco") ~ "Mexico",
      TRUE ~ state
    )
  ) %>%
  # Overwrite original var column with the cleaned/harmonized version
  mutate(var = var_clean) %>%
  select(-var_clean) %>%

  # 6. Classify water-body type. This paper is FRESHWATER-focused.
  #    Marine is flagged by loc_type (ocean/estuary) OR by the Eionet bathing-water
  #    category BWCat ("C" = coastal, "T" = transitional/estuarine). BWCat overrides a
  #    missing/ambiguous loc_type, which is what keeps coastal bathing sites from
  #    leaking into the "other/unknown" bucket. Groundwater is a distinct exposure
  #    pathway and is also excluded. Everything else -- rivers, lakes, reservoirs,
  #    ponds, canals, ditches, springs, wetlands, and other/unknown -- is freshwater.
  mutate(
    water_type = case_when(
      loc_type %in% c("ocean", "estuary") | BWCat %in% c("C", "T") ~ "marine",
      loc_type == "groundwater/well" ~ "groundwater",
      TRUE ~ "freshwater"
    )
  )

cat("--- WATER-TYPE BREAKDOWN (of cleaned records) ---\n")
print(clean_tab %>% count(water_type) %>% collect() %>% arrange(desc(n)))
cat("\n")

# Apply the freshwater focus: drop marine and groundwater records.
clean_tab <- clean_tab %>%
  filter(water_type == "freshwater") %>%
  select(-water_type)

# Resolve the 'other/unknown' loc_type bucket.
#   Eionet inland bathing waters encode their body type in BWCat ("L" = lake, "R" = river)
#   even when loc_type arrived as "other"/NA -- reclassify those. The marine guard above
#   leaves only BWCat L / R / NA in this bucket (no coastal "C" or transitional "T").
#   Records with NEITHER a usable loc_type NOR a BWCat signal cannot be verified as inland
#   and are DROPPED.
cat("--- 'OTHER/UNKNOWN' loc_type bucket, by BWCat (expect only L / R / NA) ---\n")
ou_bucket <- clean_tab %>% filter(loc_type == "other" | is.na(loc_type))
print(ou_bucket %>% count(BWCat) %>% collect() %>% arrange(desc(n)))
n_bucket <- ou_bucket %>% summarise(n = n()) %>% collect() %>% pull(n)

clean_tab <- clean_tab %>%
  mutate(loc_type = case_when(
    (loc_type == "other" | is.na(loc_type)) & BWCat == "L" ~ "lake",
    (loc_type == "other" | is.na(loc_type)) & BWCat == "R" ~ "river/stream",
    TRUE ~ loc_type
  )) %>%
  filter(!(loc_type == "other" | is.na(loc_type)))

cat("  bucket size:", n_bucket,
    "-> reclassified via BWCat (L->lake, R->river/stream); BWCat=NA records dropped.\n\n")

cat("Writing FRESHWATER cleaned data to", output_file, "with ZSTD compression...\n")
write_feather(clean_tab, output_file, compression = "zstd")

cat("Reading cleaned data file to verify...\n")
clean_tab_check <- read_feather(output_file, as_data_frame = FALSE)
n_clean <- nrow(clean_tab_check)
cat("Cleaned rows:", n_clean, "\n")
cat("Removed rows in total:", n_original - n_clean, " (", round((n_original - n_clean) / n_original * 100, 3), "% of original data)\n\n")

cat("--- CLEANED VARIABLES DISTRIBUTION ---\n")
var_dist <- clean_tab_check %>%
  count(var) %>%
  collect() %>%
  arrange(desc(n))
print(var_dist)
cat("\n")

cat("--- CLEANED COUNTRIES (TOP 10) ---\n")
country_dist <- clean_tab_check %>%
  count(country) %>%
  collect() %>%
  arrange(desc(n)) %>%
  head(10)
print(country_dist)
cat("\n")

cat("--- FRESHWATER ECOSYSTEM (loc_type) DISTRIBUTION ---\n")
loc_dist <- clean_tab_check %>%
  count(loc_type) %>%
  collect() %>%
  arrange(desc(n))
print(loc_dist)
cat("\n")

cat("Dataset cleaned successfully and saved to:", output_file, "\n")
