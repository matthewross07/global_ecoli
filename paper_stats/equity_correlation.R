# Freshwater monitoring density vs waterborne-disease burden (Results 3.2).
# Reproduces: 52 countries with open freshwater data; Spearman rho = -0.71
# (p = 5e-9) between freshwater sites per million people and WHO WASH mortality;
# 94 countries at/above median WASH mortality, 73 (78%) absent from the open
# record, 17 of the 20 highest-burden countries absent.
#
# Run from the repo root:  Rscript paper_stats/equity_correlation.R
#
# Data (paper_stats/data/):
#   pop.csv   UN World Population Prospects, national population (undesa_wpp)
#   wash.csv  WHO GHO mortality attributable to unsafe WASH, SDG 3.9.2 (who_gho_wash)
# fw_sites_by_country.csv is rebuilt here from the cleaned feather and written to
# the output directory (a copy is cached in data/ for reference).
# NOTE: an unsafe-water-only mortality series (uw.csv)
# was explored during drafting but is NOT used; that OWID chart is
# non-redistributable and returns HTTP 403, so all reported numbers use wash.csv.
suppressMessages({ library(arrow); library(dplyr); library(data.table) })
source("paths.R")

## freshwater monitoring sites per country (distinct sites, coord-hashed if unnamed)
d  <- read_feather(fib_in("fecal_indicators_clean.feather"), as_data_frame = FALSE)
fw <- d %>% filter(realm == "freshwater") %>% select(country, site_id, lat, lon) %>% collect()
setDT(fw)
fw[, sk := fifelse(is.na(site_id), paste0("c_", round(lat, 4), "_", round(lon, 4)), site_id)]
sites <- fw[!is.na(country), .(sites = uniqueN(sk)), by = country][order(-sites)]
fwrite(sites, fib_out("fw_sites_by_country.csv"))
cat("countries with open freshwater monitoring:", nrow(sites), "\n")

## join to 2019 population and WASH mortality
pop  <- fread("paper_stats/data/pop.csv")[Year == 2019, .(country = Entity, pop = Population)]
wash <- fread("paper_stats/data/wash.csv"); setnames(wash, 4, "wm")
wash <- wash[Year == 2019, .(country = Entity, wm)]
m <- merge(pop, wash, by = "country")
m <- merge(m, sites, by = "country", all.x = TRUE); m[is.na(sites), sites := 0]
m[, dens := sites / (pop / 1e6)]                       # freshwater sites per million people

## correlation among countries that share open data
wd <- m[sites > 0]
r  <- suppressWarnings(cor.test(wd$dens, wd$wm, method = "spearman"))
cat(sprintf("Spearman density vs WASH mortality (n=%d with data): rho=%.2f, p=%.1g\n",
            nrow(wd), r$estimate, r$p.value))

## absence among high-burden countries
hb <- m[wm >= median(m$wm)]
cat(sprintf("countries at/above median WASH mortality: %d; absent from open record: %d (%.0f%%)\n",
            nrow(hb), sum(hb$sites == 0), 100 * mean(hb$sites == 0)))
top <- m[order(-wm)][1:20]
cat(sprintf("of the 20 highest-burden countries, %d contribute zero open freshwater records\n",
            sum(top$sites == 0)))
