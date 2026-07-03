suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
x <- d %>% filter(country=="South Africa", var=="Escherichia coli") %>%
     select(site_id,lat,lon,date,val) %>% collect()
setDT(x); x[, yr:=as.integer(format(date,"%Y"))]
sy <- x[, .(n=.N, exceed=round(100*mean(val>410),1), med=round(median(val)),
   max=round(max(val)), lat=round(first(lat),3), lon=round(first(lon),3)), by=.(site_id,yr)]
cat("=== SA E.coli site-years with >=45 samples (weekly+ within a year), top by recency then n ===\n")
print(sy[n>=45][order(-yr,-n)][1:18])
