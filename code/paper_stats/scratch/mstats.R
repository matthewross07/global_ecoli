suppressMessages({library(arrow);library(dplyr);library(data.table);library(lubridate)})
d<-read_feather("fecal_indicators_clean.feather",as_data_frame=FALSE)
D<-d%>%select(source,country,var,realm,loc_type,site_id,lat,lon,date,val)%>%collect();setDT(D)
N<-nrow(D)
cat("TOTAL:",N," | dates:",as.character(min(D$date)),"to",as.character(max(D$date)),"\n")
cat("\n==REALM==\n");print(D[,.(n=.N,pct=round(100*.N/N,2)),by=realm][order(-n)])
cat("\n==INDICATOR==\n");print(D[,.(n=.N,pct=round(100*.N/N,2)),by=var][order(-n)])
cat("\n==ECOSYSTEM==\n");print(D[,.(n=.N,pct=round(100*.N/N,2)),by=loc_type][order(-n)])
cat("\n==SOURCE==\n");print(D[,.(n=.N),by=source][order(-n)])
euro<-c("United Kingdom","France","Germany","Spain","Italy","Netherlands","Belgium","Portugal","Ireland","Denmark","Sweden","Finland","Norway","Poland","Austria","Greece","Czechia","Czech Republic","Hungary","Romania","Bulgaria","Croatia","Slovenia","Slovakia","Estonia","Latvia","Lithuania","Luxembourg","Cyprus","Malta","Switzerland","Iceland")
D[,region:=fcase(country=="United States","US",country=="Canada","Canada",country%in%euro,"Europe",default="RoW")]
cat("\n==REGION==\n");print(D[,.(n=.N,pct=round(100*.N/N,2)),by=region][order(-n)])
cat("\n==COUNTRY top12==\n");print(D[,.(n=.N,pct=round(100*.N/N,2)),by=country][order(-n)][1:12])
D[,sk:=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id)]
sn<-D[,.(n=.N),by=sk]
cat("\n==SITES==\n  distinct:",uniqueN(D$sk)," >=100obs:",round(100*mean(sn$n>=100),2),"% >=500obs:",round(100*mean(sn$n>=500),2),"%\n")
cad<-unique(D[,.(sk,date)])[order(sk,date),.(nd=.N,mg=as.numeric(median(diff(date)))),by=sk][nd>=2]
cat("  multi-sample(>=2 days):",nrow(cad),"\n")
cad[,band:=fcase(mg<=1,"Daily",mg<=3,"NearDaily",mg<=7,"Weekly",mg<=31,"Monthly",mg<=92,"Quarterly",mg<=366,"Yearly",default="Longer")]
print(cad[,.(pct=round(100*.N/nrow(cad),2)),by=band][order(-pct)])
gen<-function(rl,vv,thr){x<-D[realm==rl&var==vv];x[,yr:=year(date)]
  dd<-x[,.(v=mean(val)),by=.(sk,country,yr,date)];sy<-dd[order(sk,date),.(days=.N,g=as.numeric(median(diff(date)))),by=.(sk,country,yr)]
  keep<-unique(sy[yr>=2018&days>=30&g<=3,.(sk,country)]);pool<-x[sk%in%keep$sk]
  list(k=keep,safe=round(100*mean(pool$val<=thr),1),ns=nrow(pool))}
gf<-gen("freshwater","Escherichia coli",410);gm<-gen("marine","Enterococci",130)
cat("\n==NEAR-DAILY==\n  fresh:",nrow(gf$k),"sites safe",gf$safe,"%(n=",gf$ns,") | marine:",nrow(gm$k),"sites safe",gm$safe,"%(n=",gm$ns,")\n")
allg<-rbind(gf$k,gm$k);cat("  total:",nrow(allg)," US-share:",round(100*mean(allg$country=="United States"),1),"%\n")
print(allg[,.N,by=country][order(-N)][1:6])
cs<-function(id,vv,thr,yr){x<-D[site_id==id&var==vv&year(date)==yr];cat(sprintf("  %-22s y%d n=%d exc=%.1f%% med=%d max=%d\n",id,yr,nrow(x),100*mean(x$val>thr),round(median(x$val)),round(max(x$val))))}
cat("\n==CASES==\n");cs("lawa_lawa-102417","Escherichia coli",410,2020);cs("datastream_804997","Escherichia coli",410,2023);cs("CABEACH_WQX-MDRH-1","Enterococci",130,2024);cs("uk_bwq_SW-70511008","Enterococci",130,2024)
