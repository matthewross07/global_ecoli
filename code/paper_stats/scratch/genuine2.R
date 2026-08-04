suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
prep <- function(realm_sel, var_sel){
  x <- d %>% filter(realm==realm_sel, var==var_sel) %>% select(site_id,lat,lon,country,date,val) %>% collect(); setDT(x)
  x[, `:=`(sk=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id), y=as.integer(format(date,"%Y")))]
  x
}
fe<-prep("freshwater","Escherichia coli"); me<-prep("marine","Enterococci")
# genuine near-daily SITE set (>=30 distinct days, distinct-day gap<=3, in any yr>=2018)
gset <- function(x){ dd<-x[, .(v=mean(val)), by=.(sk,country,y,date)]
  sy<-dd[order(sk,date),.(days=.N,g=as.numeric(median(diff(date)))),by=.(sk,country,y)][y>=2018&days>=30&g<=3]
  unique(sy[,.(sk,country)]) }
gf<-gset(fe); gm<-gset(me)
cat("GENUINE near-daily UNIQUE sites: fresh=",nrow(gf)," marine=",nrow(gm),"\n")
cat("fresh by country:\n"); print(gf[,.N,by=country][order(-N)][1:8])
cat("marine by country:\n"); print(gm[,.N,by=country][order(-N)][1:8])
# verify candidate sites: best near-daily year
bestyr <- function(x,id,thr){ q<-x[sk==id]; dd<-q[,.(v=mean(val)),by=.(y,date)]
  sy<-dd[order(y,date),.(days=.N,g=as.numeric(median(diff(date))),exceed=round(100*mean(v>thr),1)),by=y][days>=20]
  cat(sprintf("  %-20s lat/lon %.3f,%.3f:\n",id,q$lat[1],q$lon[1])); print(sy[order(-days)][1:3]) }
cat("\n=== candidate sites, best years (distinct days) ===\n")
bestyr(fe,"lawa_lawa-102417",410)
bestyr(fe,"datastream_804997",410)
bestyr(me,"CABEACH_WQX-MDRH-1",130)
bestyr(me,"uk_bwq_SW-70511008",130)
