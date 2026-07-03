suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
genuine <- function(realm_sel, var_sel){
  x <- d %>% filter(realm==realm_sel, var==var_sel) %>% select(site_id,lat,lon,country,date,val) %>% collect(); setDT(x)
  x[, `:=`(sk=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id), yr=as.integer(format(date,"%Y")))]
  dd <- x[, .(val=mean(val)), by=.(sk,country,yr,date)]                  # collapse same-day replicates
  sy <- dd[order(sk,date), .(days=.N, dgap=as.numeric(median(diff(date)))), by=.(sk,country,yr)]
  list(x=x, qual=sy[yr>=2018 & days>=30 & !is.na(dgap) & dgap<=3])
}
fe<-genuine("freshwater","Escherichia coli"); me<-genuine("marine","Enterococci")
cat("GENUINE near-daily (>=30 distinct days, distinct-day median gap<=3, yr>=2018):\n")
cat("  fresh E.coli sites:", uniqueN(fe$qual$sk), " | marine enterococci sites:", uniqueN(me$qual$sk), "\n")
cat("  fresh by country:\n"); print(fe$qual[,.N,by=country][order(-N)][1:8])
cat("  marine by country:\n"); print(me$qual[,.N,by=country][order(-N)][1:8])
cat("\n=== verify current 4 cases (distinct days / distinct-day gap in plotted year) ===\n")
chk <- function(g,id,yr){q<-g$x[sk==id & yr==yr]; dd<-q[,.(v=mean(val)),by=date][order(date)]; cat(sprintf("  %-20s yr%d: days=%d dgap=%.1f\n",id,yr,nrow(dd),as.numeric(median(diff(dd$date)))))}
chk(fe,"lawa_lawa-102417",2020); chk(fe,"datastream_804997",2018)
chk(me,"CABEACH_WQX-MDRH-1",2023); chk(me,"uk_bwq_NE-49000767",2020)
cat("\n=== genuine UK MARINE candidates (>=40 distinct days, dgap<=3, recent) ===\n")
ukm <- me$x[country=="United Kingdom"]; ukm[, `:=`(sk=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id), yr=as.integer(format(date,"%Y")))]
uq <- ukm[, .(v=mean(val)), by=.(sk,yr,date)][order(sk,yr,date),.(days=.N, dgap=as.numeric(median(diff(date))), exceed=NA_real_), by=.(sk,yr)][days>=40 & dgap<=3 & yr>=2018]
ex <- ukm[, .(v=mean(val)), by=.(sk,yr,date)][, .(exceed=round(100*mean(v>130),1)), by=.(sk,yr)]
print(merge(uq[,.(sk,yr,days,dgap)], ex, by=c("sk","yr"))[order(-days)][1:10])
