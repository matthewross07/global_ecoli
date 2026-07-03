suppressMessages({library(data.table)})
fw<-fread("/tmp/fw_sites_by_country.csv")
pop<-fread("/tmp/pop.csv")[Year==2019,.(country=Entity,pop=Population)]
wash<-fread("/tmp/wash.csv");setnames(wash,4,"wm");wash<-wash[Year==2019,.(country=Entity,wm)]
m<-merge(pop,wash,by="country");m<-merge(m,fw,by="country",all.x=TRUE);m[is.na(sites),sites:=0]
m[,dens:=sites/(pop/1e6)]
wd<-m[sites>0]
r<-suppressWarnings(cor.test(wd$dens,wd$wm,method="spearman"))
cat(sprintf("Spearman density vs WASH mortality (n=%d with data): rho=%.2f, p=%.1g\n",nrow(wd),r$estimate,r$p.value))
hb<-m[wm>=median(m$wm)]
cat(sprintf("countries at/above median WASH mortality: %d; absent from open record: %d (%.0f%%)\n",nrow(hb),sum(hb$sites==0),100*mean(hb$sites==0)))
top<-m[order(-wm)][1:20]
cat(sprintf("of 20 highest-burden countries, %d contribute zero open freshwater records\n",sum(top$sites==0)))
