suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
x <- d %>% filter(country=="South Africa") %>%
     select(site_id,realm,loc_type,var,lat,lon,date,val) %>% collect()
setDT(x)
cat("=== South Africa: realm + indicator coverage ===\n")
print(x[, .N, by=.(realm, var)][order(-N)])
x[, sk := fifelse(is.na(site_id), paste0("c_",round(lat,4),"_",round(lon,4)), site_id)]
# best-sampled SA sites (per indicator), lowest median gap
s <- x[order(sk,date), .(n=.N, max_d=max(date), med_gap=as.numeric(median(diff(date))),
   realm=first(realm), var=first(var), lat=round(first(lat),3), lon=round(first(lon),3)), by=.(sk,var)]
cat("\n=== best-sampled SA sites (median gap <= 14 d, n>=20), top 15 ===\n")
print(s[!is.na(med_gap) & med_gap<=14 & n>=20][order(med_gap,-n)][1:15])
cat("\n=== overall SA cadence: distribution of per-site median gaps ===\n")
print(s[n>=10, .(.N, pct=round(100*.N/nrow(s[n>=10]),1)), by=.(gap_band=fcase(med_gap<=8,"weekly_or_better", med_gap<=16,"biweekly", med_gap<=45,"monthly", default="coarser"))][order(gap_band)])
