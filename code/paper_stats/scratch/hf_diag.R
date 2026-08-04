suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
hf_count <- function(realm_sel, var_sel, gap) {
  x <- d %>% filter(realm==realm_sel, var==var_sel) %>% select(site_id,lat,lon,country,date) %>% collect(); setDT(x)
  x[, sk := fifelse(is.na(site_id), paste0("c_",round(lat,4),"_",round(lon,4)), site_id)]
  s <- x[order(sk,date), .(n=.N, med_gap=as.numeric(median(diff(date))), country=first(country)), by=sk]
  s[!is.na(med_gap) & med_gap<=gap & n>=30]
}
for (g in c(3, 8)) {
  fe <- hf_count("freshwater","Escherichia coli",g); me <- hf_count("marine","Enterococci",g)
  cat(sprintf("\n=== gap<=%d, n>=30 ===  fresh E.coli sites=%d | marine enterococci sites=%d | TOTAL=%d\n",
      g, nrow(fe), nrow(me), nrow(fe)+nrow(me)))
  cat("  fresh top countries:\n"); print(fe[, .N, by=country][order(-N)][1:8])
  cat("  marine top countries:\n"); print(me[, .N, by=country][order(-N)][1:8])
}
cat("\n=== case-site cadence (median gap over full record) ===\n")
for (cs in list(c("187961","Escherichia coli","freshwater"),
                c("lawa_gdc-00033","Escherichia coli","freshwater"),
                c("CABEACH_WQX-MDRH-1","Enterococci","marine"),
                c("uk_bwq_SW-81814942","Enterococci","marine"))) {
  x <- d %>% filter(site_id==cs[1], var==cs[2]) %>% select(date,lat,lon) %>% collect(); setDT(x); x <- x[order(date)]
  cat(sprintf("  %-22s n=%d med_gap=%.1f  lat,lon = %.4f, %.4f\n", cs[1], nrow(x),
      as.numeric(median(diff(x$date))), x$lat[1], x$lon[1]))
}
