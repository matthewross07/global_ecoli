suppressMessages({library(arrow);library(dplyr);library(data.table)})
d<-read_feather("fecal_indicators_clean.feather",as_data_frame=FALSE)
ss<-d%>%select(site_id,lat,lon,date)%>%collect();setDT(ss)
ss[,sk:=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id)]
cad<-unique(ss[,.(sk,date)])[order(sk,date),.(nd=.N,mg=as.numeric(median(diff(date)))),by=sk][nd>=2]
cad[,band:=fcase(mg<=1,"Daily",mg<=3,"Near-daily",mg<=7,"Weekly",mg<=31,"Monthly",mg<=92,"Quarterly",mg<=366,"Yearly",default="Longer")]
print(cad[,.(pct=round(100*.N/nrow(cad),1)),by=band][order(-pct)])
