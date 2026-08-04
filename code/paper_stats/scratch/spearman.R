suppressMessages({library(data.table)})
fw<-fread("/tmp/fw_sites_by_country.csv")            # country, sites
wash<-fread("/tmp/wash.csv"); setnames(wash,4,"wash_mort")
wash<-wash[Year==2019,.(country=Entity,wash_mort)]
pop<-fread("/tmp/pop.csv")[Year==2019,.(country=Entity,pop=Population)]
# alias our country names -> OWID
ali<-c("United States"="United States","United Kingdom"="United Kingdom","Czechia"="Czechia","Czech Republic"="Czechia","Russia"="Russia")
fw[,country:=ifelse(country %in% names(ali), ali[country], country)]
m<-merge(wash,pop,by="country")                      # all countries with burden+pop
m<-merge(m,fw,by="country",all.x=TRUE)               # add our sites (NA if absent)
m[is.na(sites),sites:=0]
m[,dens:=sites/(pop/1e6)]                             # freshwater sites per million people
cat("countries with WASH+pop:",nrow(m)," | of which in our record:",sum(m$sites>0),"\n")
# which of our 53 failed to match?
unmatched<-setdiff(fw$country, m$country)
cat("UNMATCHED from our data:",paste(unmatched,collapse=", "),"\n\n")
# correlations
withdat<-m[sites>0]
cat("== Spearman: freshwater monitoring density vs WASH mortality rate ==\n")
r1<-cor.test(withdat$dens,withdat$wash_mort,method="spearman");cat(sprintf("  countries WITH open data (n=%d): rho=%.3f p=%.2g\n",nrow(withdat),r1$estimate,r1$p.value))
r2<-cor.test(m$dens,m$wash_mort,method="spearman");cat(sprintf("  ALL countries, absent=0 (n=%d): rho=%.3f p=%.2g\n",nrow(m),r2$estimate,r2$p.value))
# illustrative contrast
cat("\nmedian density, low-burden (wash_mort<1):",round(median(m[wash_mort<1]$dens),1),"sites/M (n=",nrow(m[wash_mort<1]),")\n")
cat("median density, high-burden (wash_mort>10):",round(median(m[wash_mort>10]$dens),2),"sites/M (n=",nrow(m[wash_mort>10]),")\n")
