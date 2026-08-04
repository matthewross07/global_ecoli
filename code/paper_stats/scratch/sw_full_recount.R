suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
N <- d %>% summarise(n=n()) %>% collect() %>% pull(n)
europe <- c("France","United Kingdom","Spain","Germany","Denmark","Croatia","Greece","Netherlands","Italy","Belgium","Malta","Sweden","Poland","Ireland","Finland","Austria","Czechia","Portugal","Hungary","Cyprus","Lithuania","Switzerland","Latvia","Slovenia","Estonia","Slovakia","Albania","Bulgaria","Montenegro","Luxembourg","Romania")
cat("TOTAL surface-water N:", N, "\n")
cc <- d %>% count(country) %>% collect(); cc$region <- ifelse(cc$country=="United States","US",ifelse(cc$country=="Canada","Canada",ifelse(cc$country %in% europe,"Europe","RoW")))
ag <- aggregate(n~region,cc,sum); ag$pct <- round(100*ag$n/sum(ag$n),1); cat("\n[GEOGRAPHY]\n"); print(ag)
cat("\n[INDICATOR]\n"); print(d %>% count(var) %>% collect() %>% arrange(desc(n)) %>% mutate(pct=round(100*n/N,1)) %>% as.data.frame())
cat("\n[REALM]\n"); print(d %>% count(realm) %>% collect() %>% mutate(pct=round(100*n/N,1)) %>% as.data.frame())
cat("\n[ECOSYSTEM]\n"); print(d %>% count(loc_type) %>% collect() %>% arrange(desc(n)) %>% mutate(pct=round(100*n/N,1)) %>% as.data.frame())

# ---- cadence (all indicators) ----
ss <- d %>% select(site_id, lat, lon, date) %>% collect()
setDT(ss); ss[, sk := fifelse(is.na(site_id), paste0("c_",round(lat,4),"_",round(lon,4)), site_id)]
site <- ss[order(sk,date), .(n=.N, span=as.numeric(max(date)-min(date))), by=sk]
cat("\n[SITES] total:", nrow(site), " | >=100 obs:", round(100*mean(site$n>=100),1),"% | >=500:", round(100*mean(site$n>=500),1),"%\n")
mm <- site[n>=2]; mm[, ai := span/(n-1)]
mm[, band := fcase(ai<=1.5,"Daily", ai<=8,"Weekly", ai<=31,"Monthly", ai<=92,"Quarterly", ai<=366,"Yearly", default="Longer")]
cat("[RETURN INTERVALS] (multi-sample sites, n=",nrow(mm),")\n")
print(mm[, .(pct=round(100*.N/nrow(mm),1)), by=band][order(-pct)])

# ---- realm-specific high-frequency safety ----
hf <- function(realm_sel, var_sel, thr) {
  x <- d %>% filter(realm==realm_sel, var==var_sel) %>% select(site_id,lat,lon,country,state,date,val) %>% collect()
  setDT(x); x[, sk := fifelse(is.na(site_id), paste0("c_",round(lat,4),"_",round(lon,4)), site_id)]
  s <- x[order(sk,date), .(n=.N, med_gap=as.numeric(median(diff(date)))), by=sk]
  keys <- s[!is.na(med_gap) & med_gap<=3 & n>=30, sk]
  pool <- x[sk %in% keys]
  cat(sprintf("\n[HF %s / %s, thr=%d] sites=%d samples=%d | safe(<=thr)=%.1f%% unsafe=%.1f%%\n",
    realm_sel, var_sel, thr, length(keys), nrow(pool), 100*mean(pool$val<=thr), 100*mean(pool$val>thr)))
  list(x=x, s=s, keys=keys)
}
fw <- hf("freshwater","Escherichia coli",410)
mar <- hf("marine","Enterococci",130)
# sensitivity: freshwater at old 235
cat("  (freshwater E. coli at 235 for comparison: safe=",
    round(100*mean(fw$x[sk %in% fw$keys]$val<=235),1),"%)\n")

# ---- marine case-study candidates ----
cat("\n[MARINE CASE CANDIDATES] high-freq marine enterococci sites, top by n in 2023-capable range\n")
mx <- mar$x; setDT(mx); mx[, yr := as.integer(format(date,"%Y"))]
cand <- mx[sk %in% mar$keys, .(n=.N, max_d=max(date), pct130=round(100*mean(val>130),1),
   med=round(median(val)), country=first(country), state=first(state),
   lat=round(first(lat),3), lon=round(first(lon),3)), by=sk][order(-n)][1:12]
print(cand)
