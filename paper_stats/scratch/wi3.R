suppressMessages({library(arrow);library(dplyr);library(data.table);library(lubridate)})
d<-read_feather("fecal_indicators_clean.feather",as_data_frame=FALSE)
w<-d%>%filter(state=="Wisconsin",var=="Escherichia coli")%>%select(site_id,lat,lon,loc_type,date)%>%collect();setDT(w)
w[,sk:=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id)]
sy<-unique(w[,.(sk,date)])[order(sk,date),.(nd=.N,mg=as.numeric(median(diff(date))),
   span=as.numeric(max(date)-min(date))),by=.(sk,yr=year(date))]
info<-w[,.(loc=first(loc_type),lat=round(first(lat),3),lon=round(first(lon),3)),by=sk]
sy<-merge(sy,info,by="sk")
sy[,band:=fcase(mg<=2&nd>=40,"DAILY", mg>=20&mg<=36&nd>=9&span>=250,"MONTHLY",
   mg>=45&mg<=120&nd>=4&nd<=8&span>=200,"QUARTERLY",default="")]
# southern WI (Madison/Milwaukee belt), 2022
for(Y in c(2022,2021,2023)){
  cat("\n===== YEAR",Y,"(southern WI, lat 42.8-43.4) =====\n")
  for(B in c("DAILY","MONTHLY","QUARTERLY")){
    cat("--",B,"--\n")
    print(head(sy[band==B & yr==Y & lat>=42.8 & lat<=43.4][order(-nd)][,.(sk,loc,nd,mg,span,lat,lon)],3))
  }
}
