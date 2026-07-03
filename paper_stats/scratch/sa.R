suppressMessages({library(arrow);library(dplyr);library(data.table);library(lubridate)})
d<-read_feather("fecal_indicators_clean.feather",as_data_frame=FALSE)
sa<-d%>%filter(source=="NMMP",var=="Escherichia coli")%>%select(site_id,lat,lon,date,val)%>%collect();setDT(sa)
sa[,sk:=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id)]
cat("NMMP E.coli records:",nrow(sa)," sites:",uniqueN(sa$sk),"\n")
# per-site geometric mean (use pmax(val,1) to avoid log0)
gm<-sa[,.(gmean=exp(mean(log(pmax(val,1)))), n=.N),by=sk][n>=3]
cat("sites with >=3 samples:",nrow(gm),"\n")
cat("median of per-site geomean E.coli:",round(median(gm$gmean)),"\n")
for(t in c(126,235,400,410,1000)) cat(sprintf("  frac sites geomean > %d: %.1f%%\n",t,100*mean(gm$gmean>t)))
# sampling cadence (distinct-day median gap) per site
cad<-unique(sa[,.(sk,date)])[order(sk,date),.(nd=.N,mg=as.numeric(median(diff(date)))),by=sk][nd>=2]
cat("median per-site sampling interval (days):",round(median(cad$mg)),"\n")
cat("  cadence quartiles:",paste(round(quantile(cad$mg,c(.25,.5,.75))),collapse=" / "),"\n")
