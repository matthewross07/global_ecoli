# Compliance with the 2012 US EPA recreational water quality criteria assessed
# as the criteria are written, and classification under the 2021 WHO
# recreational guidelines (Nature Water revision: Results "Compliance assessed
# as the criteria are written", Limitations, Methods "Sampling cadence and
# safety metrics").
#
# Three tests, each labeled by what it corresponds to in the manuscript:
#   1. 30-day intervals at the near-daily site-years. A site-year fails if any
#      30-day interval ending on a sampling day and holding >= 10 samples has a
#      geometric mean above the GM magnitude (126 E. coli / 35 enterococci) or
#      more than 10% of samples above the statistical threshold value (410 / 130).
#   2. The same test applied to the calendar year, for every site-year holding
#      >= 10 samples of the relevant indicator in the relevant realm.
#   3. WHO 2021: enterococci in both realms, site-years with >= 10 samples,
#      95th percentile <= 40 (category A) and > 200 (above the guideline value).
#
# "Sample" means a distinct sampling day, with same-day replicates collapsed to
# their geometric mean, exactly as in make_fig5_downsampling.R (whose near-daily
# ground truth this script shares via the same cache). The raw-record variant is
# printed alongside as a sensitivity check.
suppressMessages({ library(arrow); library(dplyr); library(data.table); library(lubridate) })
source("paths.R")

FRESH_THR <- 410; MARINE_THR <- 130          # statistical threshold values
FRESH_GM  <- 126; MARINE_GM  <- 35           # geometric mean magnitudes
MIN_N     <- 10                              # samples needed to apply a test

d <- read_feather(fib_in("fecal_indicators_clean.feather"), as_data_frame = FALSE)

## ---- daily-collapsed records for the two indicator/realm pairs the criteria cover
load_pair <- function(rl, vv) {
  x <- d %>% filter(realm == rl, var == vv) %>%
    select(site_id, lat, lon, loc_type, date, val) %>% collect(); setDT(x)
  x[, sk := fifelse(is.na(site_id), paste0("c_", round(lat, 4), "_", round(lon, 4)), site_id)]
  x[, yr := year(date)]
  x
}
daily <- function(x) x[, .(v = exp(mean(log(pmax(val, 1)))), loc = first(loc_type)), by = .(sk, yr, date)]

## ---- near-daily site-years: identical rule and cache to make_fig5_downsampling.R
build_realm <- function(rl, vv, thr) {
  dd <- daily(load_pair(rl, vv))
  q <- dd[order(sk, date), .(days = .N, mg = as.numeric(median(diff(date)))), by = .(sk, yr)][
    yr >= 2018 & days >= 30 & mg <= 3]
  dd[, ky := paste(sk, yr)]; q[, ky := paste(sk, yr)]
  out <- dd[ky %in% q$ky]; out[, `:=`(realm = rl, thr = thr)]; out
}
if (file.exists(FIB_CACHE)) {
  S <- readRDS(FIB_CACHE)
} else {
  S <- rbind(build_realm("freshwater", "Escherichia coli", FRESH_THR),
             build_realm("marine", "Enterococci", MARINE_THR))
  saveRDS(S, FIB_CACHE)
}
S[, gthr := fifelse(realm == "freshwater", FRESH_GM, MARINE_GM)]
cat("near-daily site-years:", uniqueN(S$ky), " sites:", uniqueN(S$sk), "\n")
print(S[, .(site_years = uniqueN(ky), sites = uniqueN(sk)), by = realm])

## ---- test 1: 30-day intervals at the near-daily site-years
window_fail <- function(z, thr, gthr) {
  # z: one site-year, sorted by date, columns date, v. For each sampling day as
  # window end, look back 30 days inclusive (day-29 .. day).
  dd <- as.integer(z$date); lv <- log(z$v); ex <- as.numeric(z$v > thr)
  cs_l <- cumsum(lv); cs_e <- cumsum(ex)
  st <- findInterval(dd - 30, dd) + 1L            # first index with date >= day-29
  n  <- seq_along(dd) - st + 1L
  gm <- exp((cs_l - c(0, cs_l)[st]) / n)
  fr <- (cs_e - c(0, cs_e)[st]) / n
  ok <- n >= MIN_N
  if (!any(ok)) return(NULL)
  data.table(loc = z$loc[1], n_max = max(n), gm_fail = any(gm[ok] > gthr), stv_fail = any(fr[ok] > 0.10),
             annual_gm_fail = exp(mean(lv)) > gthr, annual_stv_fail = mean(ex) > 0.10)
}
r30 <- S[order(ky, date), window_fail(.SD, thr[1], gthr[1]), by = .(ky, realm)]
r30[, either := gm_fail | stv_fail]
report30 <- function(dt, label) {
  cat(sprintf("\n[%s]\n", label))
  s <- dt[, .(site_years = .N,
              gm_fail_pct = round(100 * mean(gm_fail), 1),
              stv_fail_pct = round(100 * mean(stv_fail), 1),
              either_pct = round(100 * mean(either), 1),
              annual_stv_fail_pct = round(100 * mean(annual_stv_fail), 1),
              annual_gm_fail_pct = round(100 * mean(annual_gm_fail), 1),
              annual_either_pct = round(100 * mean(annual_stv_fail | annual_gm_fail), 1)),
          by = realm]
  print(s)
}
cat("\n=== TEST 1: EPA criteria on 30-day intervals, near-daily site-years ===\n")
cat("(fresh = E. coli 126/410; marine = enterococci 35/130; 'annual_*' = the same\n")
cat(" site-years assessed on the calendar year, for the Limitations comparison)\n")
report30(r30, "all near-daily site-years (1,321)")
report30(r30[loc != "estuary"], "estuary site-years excluded, as in Fig. 5 (1,308)")

## ---- test 2: calendar year, every site-year with >= 10 samples
annual <- function(x, thr, gthr, label) {
  dd <- daily(x)
  a  <- dd[, .(n = .N, gm = exp(mean(log(v))), ex = mean(v > thr), p95 = quantile(v, 0.95, names = FALSE)),
           by = .(sk, yr)]
  raw <- x[, .(n = .N, gm = exp(mean(log(pmax(val, 1)))), ex = mean(val > thr)), by = .(sk, yr)]
  a <- a[n >= MIN_N]; raw <- raw[n >= MIN_N]
  cat(sprintf("\n[%s] site-years with >= %d distinct sampling days: %d (sites %d)\n",
              label, MIN_N, nrow(a), uniqueN(a$sk)))
  cat(sprintf("   STV excursion test failed (>10%% of samples > %d): %.1f%%\n", thr, 100 * mean(a$ex > 0.10)))
  cat(sprintf("   GM test failed (geometric mean > %d):             %.1f%%\n", gthr, 100 * mean(a$gm > gthr)))
  cat(sprintf("   fails either criterion:                           %.1f%%\n", 100 * mean(a$ex > 0.10 | a$gm > gthr)))
  cat(sprintf("   share of individual samples at or below the STV:  %.1f%%\n", 100 * mean(x$val <= thr)))
  cat(sprintf("   [sensitivity: raw records as samples] n=%d, fails either: %.1f%%\n",
              nrow(raw), 100 * mean(raw$ex > 0.10 | raw$gm > gthr)))
  invisible(a)
}
cat("\n=== TEST 2: EPA criteria on the calendar year, all site-years with >= 10 samples ===\n")
fw <- load_pair("freshwater", "Escherichia coli")
a_fw <- annual(fw, FRESH_THR, FRESH_GM, "E. coli, freshwater")
rm(fw)
mr <- load_pair("marine", "Enterococci")
a_mr <- annual(mr, MARINE_THR, MARINE_GM, "Enterococci, marine")

## ---- test 3: WHO 2021, enterococci in both realms
cat("\n=== TEST 3: WHO 2021 guidelines, enterococci (both realms), 95th percentile ===\n")
en <- rbind(mr, load_pair("freshwater", "Enterococci")); rm(mr)
dd <- daily(en)
w <- dd[, .(n = .N, p95 = quantile(v, 0.95, names = FALSE)), by = .(sk, yr)][n >= MIN_N]
cat(sprintf("site-years with >= %d distinct sampling days: %d\n", MIN_N, nrow(w)))
cat(sprintf("   category A (95th percentile <= 40):   %.1f%%\n", 100 * mean(w$p95 <= 40)))
cat(sprintf("   category B (40 < p95 <= 200):         %.1f%%\n", 100 * mean(w$p95 > 40 & w$p95 <= 200)))
cat(sprintf("   above the 200/100 mL guideline value: %.1f%%\n", 100 * mean(w$p95 > 200)))
wr <- en[, .(n = .N, p95 = quantile(val, 0.95, names = FALSE)), by = .(sk, yr)][n >= MIN_N]
cat(sprintf("   [sensitivity: raw records] n=%d, A: %.1f%%, >200: %.1f%%\n",
            nrow(wr), 100 * mean(wr$p95 <= 40), 100 * mean(wr$p95 > 200)))
