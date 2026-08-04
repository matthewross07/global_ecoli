library(arrow)
library(dplyr)
library(tidyr)
library(lubridate)
source("paths.R")

# Input and Output file paths
# Input: the harmonized DB produced by the data pipeline (sibling repo).
# Output: the SURFACE-WATER cleaned dataset this paper is built from
#   (fresh + marine/coastal/estuarine; groundwater excluded). Each record
#   carries a `realm` column ("freshwater"/"marine") for realm-specific analysis.
input_file <- FIB_HARMONIZED
output_file <- fib_out("fecal_indicators_clean.feather")

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

# Canonical indicator keep-list. "enterococcus" (the marine enterococci records
# pulled for the surface-water expansion) is merged with "intestinal enterococci"
# into a single "Enterococci" class.
keep_var <- function(v) {
  case_when(
    tolower(v) %in% c("escherichia coli", "escherichia") ~ "Escherichia coli",
    tolower(v) %in% c("fecal coliform", "fecal coliforms") ~ "Fecal Coliform",
    tolower(v) %in% c("total coliform", "total coliforms") ~ "Total Coliform",
    tolower(v) %in% c("intestinal enterococci", "enterococcus") ~ "Enterococci",
    tolower(v) == "fecal streptococcus group bacteria" ~ "Fecal Streptococcus Group Bacteria",
    TRUE ~ NA_character_
  )
}

cat("Applying cleaning and standardization filters...\n")
clean_tab <- tab %>%
  # 1. Restrict to the canonical FIB indicators (case-insensitive)
  mutate(var_clean = keep_var(var)) %>%
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
  mutate(country = case_when(
    state %in% us_states ~ "United States",
    state %in% c("England", "United_kingdom") ~ "United Kingdom",
    state %in% c("Mexico", "México", "Hidalgo", "Tabasco") ~ "Mexico",
    TRUE ~ state
  )) %>%
  mutate(var = var_clean) %>%
  select(-var_clean) %>%

  # 6. Assign realm. This paper covers ALL SURFACE WATERS (fresh + marine).
  #    Marine is flagged by loc_type (ocean/estuary) OR the Eionet bathing-water
  #    category BWCat ("C" = coastal, "T" = transitional/estuarine). Groundwater
  #    (a distinct exposure pathway) is the only realm excluded.
  mutate(realm = case_when(
    loc_type %in% c("ocean", "estuary") | BWCat %in% c("C", "T") ~ "marine",
    loc_type == "groundwater/well" ~ "groundwater",
    TRUE ~ "freshwater"
  )) %>%

  # 7. Resolve ambiguous loc_type using BWCat (bathing-water body type), so that
  #    coastal/transitional/lake/river bathing sites carry an ecosystem label.
  mutate(loc_type = case_when(
    (loc_type == "other" | is.na(loc_type)) & BWCat == "C" ~ "ocean",
    (loc_type == "other" | is.na(loc_type)) & BWCat == "T" ~ "estuary",
    (loc_type == "other" | is.na(loc_type)) & BWCat == "L" ~ "lake",
    (loc_type == "other" | is.na(loc_type)) & BWCat == "R" ~ "river/stream",
    TRUE ~ loc_type
  ))

cat("--- REALM BREAKDOWN (of cleaned records) ---\n")
print(clean_tab %>% count(realm) %>% collect() %>% arrange(desc(n)))
cat("\n")

# Apply the surface-water focus: drop only groundwater.
clean_tab <- clean_tab %>% filter(realm != "groundwater")

cat("Writing SURFACE-WATER cleaned data to", output_file, "with ZSTD compression...\n")
write_feather(clean_tab, output_file, compression = "zstd")

cat("Reading cleaned data file to verify...\n")
clean_tab_check <- read_feather(output_file, as_data_frame = FALSE)
n_clean <- nrow(clean_tab_check)
cat("Cleaned rows:", n_clean, "\n")
cat("Removed rows in total:", n_original - n_clean, " (",
    round((n_original - n_clean) / n_original * 100, 3), "% of original data)\n\n")

cat("--- REALM x rows ---\n")
print(clean_tab_check %>% count(realm) %>% collect() %>% arrange(desc(n)))
cat("\n--- CLEANED INDICATOR DISTRIBUTION ---\n")
print(clean_tab_check %>% count(var) %>% collect() %>% arrange(desc(n)))
cat("\n--- CLEANED COUNTRIES (TOP 10) ---\n")
print(clean_tab_check %>% count(country) %>% collect() %>% arrange(desc(n)) %>% head(10))
cat("\n--- ECOSYSTEM (loc_type) DISTRIBUTION ---\n")
print(clean_tab_check %>% count(loc_type) %>% collect() %>% arrange(desc(n)))
cat("\nDataset cleaned successfully and saved to:", output_file, "\n")
