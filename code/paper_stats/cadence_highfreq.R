# Sampling-cadence and high-frequency statistics (Results "The actionability
# gap in sampling frequency" and "High-frequency safety and case studies";
# Figure 4 caption; Table 3 exceedance rates).
#
# Prints, from the cleaned feather: distinct-site counts and the site
# data-volume survival points (>= 100, >= 500 observations); the number of
# multi-sample sites and the distribution of their median distinct-day sampling
# interval (Figure 3B bands); the time-of-day and day-of-week distribution of
# records; the genuine near-daily site set (>= 30 distinct sampling days in a
# year >= 2018 with a distinct-day median gap <= 3 d, E. coli in fresh water and
# enterococci in marine water) with its country breakdown, its sample counts,
# and the share of those samples at or below the statistical threshold value;
# and the per-year exceedance rate of the four case-study site-years.
suppressMessages({ library(arrow); library(dplyr); library(data.table) })
source("paths.R")

FRESH_THR <- 410; MARINE_THR <- 130
d <- read_feather(fib_in("fecal_indicators_clean.feather"), as_data_frame = FALSE)

## ---- site data volume and cadence (Figure 3)
ss <- d %>% select(site_id, lat, lon, date, time_local) %>% collect(); setDT(ss)
ss[, sk := fifelse(is.na(site_id), paste0("c_", round(lat, 4), "_", round(lon, 4)), site_id)]
site <- ss[, .(n = .N), by = sk]
cat("distinct sites:", nrow(site), "\n")
for (z in c(100, 500)) cat(sprintf("  sites with >= %d observations: %.1f%%\n", z, 100 * mean(site$n >= z)))
cad <- unique(ss[, .(sk, date)])[order(sk, date), .(nd = .N, medgap = as.numeric(median(diff(date)))), by = sk][nd >= 2]
cat("multi-sample sites (>= 2 distinct sampling days):", nrow(cad), "\n")
cad[, band := fcase(medgap <= 1, "Daily", medgap <= 3, "Near-daily", medgap <= 7, "Weekly",
                    medgap <= 31, "Monthly", medgap <= 92, "Quarterly", medgap <= 366, "Yearly",
                    default = "Longer")]
print(cad[, .(sites = .N, pct = round(100 * .N / nrow(cad), 1)), by = band][
  order(factor(band, c("Daily", "Near-daily", "Weekly", "Monthly", "Quarterly", "Yearly", "Longer")))])

## ---- time of day and day of week
cat("\ntime_local: ", sprintf("%.1f%% of records carry a local time", 100 * mean(!is.na(ss$time_local))), "\n")
hr <- suppressWarnings(as.integer(substr(ss$time_local, 1, 2))); hr <- hr[!is.na(hr)]
cat(sprintf("  records with a time: %d; collected 08:00-13:59: %.1f%%; 17:00-22:59: %.1f%%\n",
            length(hr), 100 * mean(hr >= 8 & hr < 14), 100 * mean(hr >= 17 & hr < 23)))
wd <- weekdays(ss$date)
cat(sprintf("  Monday-Wednesday: %.1f%%; weekend: %.1f%%\n",
            100 * mean(wd %in% c("Monday", "Tuesday", "Wednesday")), 100 * mean(wd %in% c("Saturday", "Sunday"))))
rm(ss, site, cad)

## ---- genuine near-daily sites (Figure 4)
hf <- function(rl, vv, thr) {
  x <- d %>% filter(realm == rl, var == vv) %>% select(site_id, lat, lon, country, date, val) %>% collect(); setDT(x)
  x[, `:=`(sk = fifelse(is.na(site_id), paste0("c_", round(lat, 4), "_", round(lon, 4)), site_id),
           yr = as.integer(format(date, "%Y")))]
  dd <- x[, .(v = mean(val)), by = .(sk, yr, date)]
  sy <- dd[order(sk, date), .(days = .N, dg = as.numeric(median(diff(date)))), by = .(sk, yr)]
  keep <- unique(sy[yr >= 2018 & days >= 30 & !is.na(dg) & dg <= 3, sk])
  pool <- x[sk %in% keep]
  list(sites = pool[, .(country = first(country)), by = sk], pool = pool, thr = thr)
}
fw <- hf("freshwater", "Escherichia coli", FRESH_THR)
mr <- hf("marine", "Enterococci", MARINE_THR)
sites <- rbind(fw$sites, mr$sites)
cat(sprintf("\nnear-daily sites: %d (freshwater %d, marine %d)\n", nrow(sites), nrow(fw$sites), nrow(mr$sites)))
cat(sprintf("  in the United States: %.1f%%; elsewhere: %d\n",
            100 * mean(sites$country == "United States"), sum(sites$country != "United States")))
print(sites[country != "United States", .N, by = country][order(-N)])
cat(sprintf("  freshwater E. coli samples at these sites: %d; at or below %d: %.1f%%\n",
            nrow(fw$pool), FRESH_THR, 100 * mean(fw$pool$val <= FRESH_THR)))
cat(sprintf("  marine enterococci samples at these sites: %d; at or below %d: %.1f%%\n",
            nrow(mr$pool), MARINE_THR, 100 * mean(mr$pool$val <= MARINE_THR)))

## ---- case-study site-years (Table 3 counts every record; the Figure 4 panels
## collapse same-day replicates to their maximum, which is printed alongside)
cases <- list(c("lawa_lawa-102417", "Escherichia coli", 2020, FRESH_THR, "Gisborne, New Zealand"),
              c("datastream_804997", "Escherichia coli", 2023, FRESH_THR, "Alberta, Canada"),
              c("CABEACH_WQX-MDRH-1", "Enterococci", 2024, MARINE_THR, "Marina del Rey, United States"),
              c("uk_bwq_SW-70511008", "Enterococci", 2024, MARINE_THR, "Devon, United Kingdom"))
cat("\ncase-study site-years:\n")
for (cs in cases) {
  x <- d %>% filter(site_id == cs[1], var == cs[2]) %>% select(date, val) %>% collect(); setDT(x)
  x <- x[as.integer(format(date, "%Y")) == as.integer(cs[3])]; thr <- as.numeric(cs[4])
  dm <- x[, .(val = max(val)), by = date]
  cat(sprintf("  %-30s %s: %d records, %.1f%% above %s (%d sampling days, %.1f%% by daily maximum)\n",
              cs[5], cs[3], nrow(x), 100 * mean(x$val > thr), cs[4], nrow(dm), 100 * mean(dm$val > thr)))
}
