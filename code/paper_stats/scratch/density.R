suppressMessages({library(arrow);library(dplyr);library(data.table)})
d<-read_feather("fecal_indicators_clean.feather",as_data_frame=FALSE)
fw<-d%>%filter(realm=="freshwater")%>%select(country,site_id,lat,lon)%>%collect();setDT(fw)
fw[,sk:=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id)]
cs<-fw[!is.na(country),.(sites=uniqueN(sk)),by=country][order(-sites)]
cat("countries with freshwater monitoring:",nrow(cs),"\n")
fwrite(cs,"/tmp/fw_sites_by_country.csv")
print(cs[1:25])
