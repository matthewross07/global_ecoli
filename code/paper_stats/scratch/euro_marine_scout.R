suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
europe <- c("France","United Kingdom","Spain","Germany","Denmark","Croatia","Greece","Netherlands","Italy","Belgium","Malta","Sweden","Poland","Ireland","Finland","Austria","Czechia","Portugal","Cyprus")
x <- d %>% filter(realm=="marine", var=="Enterococci", country %in% europe) %>%
     select(site_id,country,state,lat,lon,date,val) %>% collect()
setDT(x); x[, sk := fifelse(is.na(site_id), paste0("c_",round(lat,4),"_",round(lon,4)), site_id)]
s <- x[order(sk,date), .(n=.N, max_d=max(date), med_gap=as.numeric(median(diff(date))),
   pct130=round(100*mean(val>130),1), med=round(median(val)), country=first(country),
   lat=round(first(lat),3), lon=round(first(lon),3)), by=sk][n>=40 & max_d>=as.Date("2019-01-01")]
cat("=== European marine enterococci sites (n>=40, recent), top 15 by n ===\n")
print(s[order(-n)][1:15])
cat("\n=== best-sampled European marine sites (lowest median gap), top 10 ===\n")
print(s[order(med_gap)][1:10])
