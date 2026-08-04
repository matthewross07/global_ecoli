# Geographic distribution of the surface-water dataset (Results 3.1, Table 2).
# Reproduces: United States 6,926,157 (62.3%), Europe 3,165,984 (28.5%),
# Canada 412,450 (3.7%), Rest of world 605,718 (5.5%); and the footnote that the
# U.S. total exceeds the Water Quality Portal source count (6,904,889) by the
# ~21,000 U.S. records contributed through GEMStat.
#
# Run from code/:  Rscript paper_stats/geography_table.R
#
# The region grouping (which countries count as "Europe") is the one
# methodological choice here and is defined explicitly below.
suppressMessages({ library(arrow); library(dplyr); library(data.table) })
source("paths.R")

# Region grouping for Table 2 (corrected). Albania and Montenegro -- European
# Adriatic bathing-water countries -- are included in Europe; an earlier draft of
# Table 2 had binned them into "Rest of world" (Europe 3,159,898 / RoW 611,804),
# which this corrects to Europe 3,165,984 / RoW 605,718.
europe <- c("France", "United Kingdom", "Spain", "Germany", "Denmark", "Croatia",
            "Greece", "Netherlands", "Italy", "Belgium", "Malta", "Sweden", "Poland",
            "Ireland", "Finland", "Austria", "Czechia", "Portugal",
            "Hungary", "Cyprus", "Lithuania", "Switzerland", "Latvia", "Slovenia",
            "Estonia", "Slovakia", "Albania", "Bulgaria", "Montenegro", "Luxembourg",
            "Romania")

d  <- read_feather(fib_in("fecal_indicators_clean.feather"), as_data_frame = FALSE)
cc <- d %>% count(country, source) %>% collect(); setDT(cc)
N  <- cc[, sum(n)]
cc[, region := fcase(country == "United States", "United States",
                     country == "Canada", "Canada",
                     country %in% europe, "Europe", default = "Rest of world")]

reg <- cc[, .(records = sum(n)), by = region][, share := 100 * records / N][
  order(-records)]
cat(sprintf("Total surface-water records: %d\n\n", N))
cat("Region              Records      Share\n")
for (i in seq_len(nrow(reg)))
  cat(sprintf("%-18s %9d   %5.1f%%\n", reg$region[i], reg$records[i], reg$share[i]))

# Rest-of-world leaders (paper: Mexico, South Africa, New Zealand)
row_top <- cc[region == "Rest of world", .(records = sum(n)), by = country][order(-records)][1:5]
cat("\nRest-of-world leaders:\n"); print(row_top)

# U.S. footnote: total U.S. records vs the WQP source count, GEMStat contribution
us_by_src <- cc[country == "United States", .(records = sum(n)), by = source][order(-records)]
cat("\nU.S. records by source (footnote):\n"); print(us_by_src)
cat(sprintf("U.S. total %d exceeds WQP source count %d by %d non-WQP (GEMStat) records\n",
            cc[country == "United States", sum(n)],
            us_by_src[source == "WQP", records],
            cc[country == "United States", sum(n)] - us_by_src[source == "WQP", records]))
