# Methods record cascade: harmonized -> validity filter -> realm split (Data & Methods).
# Reproduces: 11,151,268 harmonized FIB records reduced to 11,136,805 by the
# validity filter; 26,496 groundwater records removed to yield 11,110,309 surface
# observations (5,899,783 freshwater, 53.1%; 5,210,526 marine, 46.9%).
#
# Run from the repo root:  Rscript paper_stats/record_cascade.R
# Mirrors the filter/realm logic of clean_data.R (which writes the feather), so
# the staged counts match the analysis dataset exactly.
suppressMessages({ library(arrow); library(dplyr) })
source("paths.R")

tab <- read_feather(FIB_HARMONIZED, as_data_frame = FALSE)

# canonical fecal-indicator keep-list (case-insensitive), same as clean_data.R
keep_var <- function(v) dplyr::case_when(
  tolower(v) %in% c("escherichia coli", "escherichia") ~ "x",
  tolower(v) %in% c("fecal coliform", "fecal coliforms") ~ "x",
  tolower(v) %in% c("total coliform", "total coliforms") ~ "x",
  tolower(v) %in% c("intestinal enterococci", "enterococcus") ~ "x",
  tolower(v) == "fecal streptococcus group bacteria" ~ "x",
  TRUE ~ NA_character_)

n_harmonized <- tab %>% summarise(n = n()) %>% collect() %>% pull(n)

fib <- tab %>% mutate(vc = keep_var(var)) %>% filter(!is.na(vc))
n_fib <- fib %>% summarise(n = n()) %>% collect() %>% pull(n)

valid <- fib %>%
  filter(date >= as.Date("1950-01-01") & date <= as.Date("2026-12-31")) %>%
  filter(lat >= -90 & lat <= 90 & lon >= -180 & lon <= 180 & !(lat == 0 & lon == 0)) %>%
  filter(val >= 0 & val <= 1e7)
n_valid <- valid %>% summarise(n = n()) %>% collect() %>% pull(n)

realm <- valid %>% mutate(realm = case_when(
  loc_type %in% c("ocean", "estuary") | BWCat %in% c("C", "T") ~ "marine",
  loc_type == "groundwater/well" ~ "groundwater",
  TRUE ~ "freshwater"))
rc <- realm %>% count(realm) %>% collect()
setNames(rc$n, rc$realm) -> r
surface <- r[["freshwater"]] + r[["marine"]]

cat(sprintf("harmonized records (all indicators): %d\n", n_harmonized))
cat(sprintf("after FIB indicator keep:            %d\n", n_fib))
cat(sprintf("after validity filter:               %d\n", n_valid))
cat(sprintf("  groundwater (excluded):            %d\n", r[["groundwater"]]))
cat(sprintf("  freshwater:                        %d (%.1f%%)\n", r[["freshwater"]], 100 * r[["freshwater"]] / surface))
cat(sprintf("  marine:                            %d (%.1f%%)\n", r[["marine"]], 100 * r[["marine"]] / surface))
cat(sprintf("surface-water analysis dataset:      %d\n", surface))
