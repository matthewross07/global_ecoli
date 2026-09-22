# Temporal coverage of the record and indicator provenance (Nature Water
# revision, Results "Temporal coverage of the record", "Indicator and ecosystem
# composition", Table 4 First/Last columns, Abstract).
#
# Reports, from the cleaned feather: the full sampling-date span, the median
# sampling year, the share of records at or after 2000/2010/2015, the first and
# last sampling year and record count per source (Table 4), and for each
# indicator class its record count, median sampling year, and the share drawn
# from the Water Quality Portal (used for the fecal / total coliform provenance
# sentence).
suppressMessages({ library(arrow); library(dplyr); library(data.table) })
source("paths.R")

x <- read_feather(fib_in("fecal_indicators_clean.feather"), as_data_frame = FALSE) %>%
  select(source, var, date, realm) %>% collect(); setDT(x)
x[, yr := as.integer(format(date, "%Y"))]

cat("surface-water records:", nrow(x), "\n")
cat("sampling-date span:", as.character(min(x$date)), "to", as.character(max(x$date)), "\n")
cat("median sampling year:", median(x$yr), "\n")
for (y in c(2000, 2010, 2015, 2018))
  cat(sprintf("share of records from %d onward: %.1f%%\n", y, 100 * mean(x$yr >= y)))

cat("\n=== Table 4: observations, first and last sampling year, by source ===\n")
print(x[, .(observations = .N, first = min(yr), last = max(yr), median_year = median(yr)),
        by = source][order(-observations)])

cat("\n=== Indicator provenance (median year; share from the Water Quality Portal) ===\n")
print(x[, .(records = .N, share_pct = round(100 * .N / nrow(x), 1),
            first = min(yr), last = max(yr), median_year = as.integer(median(yr)),
            wqp_share_pct = round(100 * mean(source == "WQP"), 1),
            marine_share_pct = round(100 * mean(realm == "marine"), 1)),
        by = var][order(-records)])
