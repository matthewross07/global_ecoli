suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
x <- d %>% filter(site_id=="datastream_804997", var=="Escherichia coli") %>% select(date,val) %>% collect(); setDT(x)
x[, y:=as.integer(format(date,"%Y"))]
dd <- x[, .(v=mean(val)), by=.(y,date)]
print(dd[order(y,date), .(days=.N, dgap=as.numeric(median(diff(date))), exceed=round(100*mean(v>410),1), med=round(median(v))), by=y][y>=2016])
