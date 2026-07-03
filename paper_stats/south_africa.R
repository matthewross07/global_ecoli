# South Africa / NMMP summary (Results 3.7).
# Reproduces: 167,336 NMMP observations; ~1,566 well-sampled (>=3 samples) E. coli
# sites; median per-site geometric-mean concentration ~180 CFU/100 mL; about one
# fifth of sites with geometric mean >1,000 (chronically severe); median per-site
# sampling interval ~32 days.
#
# Run from the repo root:  Rscript paper_stats/south_africa.R
#
# Definitional choices made explicit: "well-sampled" = >=3 samples per site;
# per-site concentration summarized by geometric mean (log-mean, floored at 1).
suppressMessages({ library(arrow); library(dplyr); library(data.table) })

d <- read_feather("fecal_indicators_clean.feather", as_data_frame = FALSE)

# total NMMP contribution (all indicators; matches the source table)
nmmp_total <- d %>% filter(source == "NMMP") %>% summarise(n = n()) %>% collect() %>% pull(n)
cat(sprintf("NMMP total observations (all indicators): %d\n", nmmp_total))

# per-site E. coli statistics
sa <- d %>% filter(source == "NMMP", var == "Escherichia coli") %>%
  select(site_id, lat, lon, date, val) %>% collect()
setDT(sa)
sa[, sk := fifelse(is.na(site_id), paste0("c_", round(lat, 4), "_", round(lon, 4)), site_id)]
cat(sprintf("NMMP E. coli records: %d across %d sites\n", nrow(sa), uniqueN(sa$sk)))

gm <- sa[, .(gmean = exp(mean(log(pmax(val, 1)))), n = .N), by = sk][n >= 3]
cat(sprintf("well-sampled sites (>=3 samples): %d\n", nrow(gm)))
cat(sprintf("median of per-site geometric-mean E. coli: %d CFU/100 mL\n", round(median(gm$gmean))))
cat(sprintf("share of sites with geometric mean >1,000 (chronically severe): %.0f%%\n",
            100 * mean(gm$gmean > 1000)))

# per-site sampling cadence (distinct-day median gap)
cad <- unique(sa[, .(sk, date)])[order(sk, date), .(nd = .N, mg = as.numeric(median(diff(date)))),
                                 by = sk][nd >= 2]
cat(sprintf("median per-site sampling interval: %d days\n", round(median(cad$mg))))
