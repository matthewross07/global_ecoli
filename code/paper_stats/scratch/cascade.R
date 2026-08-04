suppressMessages({library(arrow);library(dplyr)})
tab<-read_feather("../../pipeline/data/harmonized/harmonized.feather",as_data_frame=FALSE)
cat("harmonized total:",nrow(tab),"\n")
kv<-function(v) dplyr::case_when(
 tolower(v)%in%c("escherichia coli","escherichia")~"x",
 tolower(v)%in%c("fecal coliform","fecal coliforms")~"x",
 tolower(v)%in%c("total coliform","total coliforms")~"x",
 tolower(v)%in%c("intestinal enterococci","enterococcus")~"x",
 tolower(v)=="fecal streptococcus group bacteria"~"x", TRUE~NA_character_)
cl<-tab%>%mutate(vc=kv(var))%>%filter(!is.na(vc))%>%
 filter(date>=as.Date("1950-01-01")&date<=as.Date("2026-12-31"))%>%
 filter(lat>=-90&lat<=90&lon>=-180&lon<=180&!(lat==0&lon==0))%>%filter(val>=0&val<=1e7)%>%
 mutate(realm=case_when(loc_type%in%c("ocean","estuary")|BWCat%in%c("C","T")~"marine",
   loc_type=="groundwater/well"~"groundwater",TRUE~"freshwater"))
cnt<-cl%>%count(realm)%>%collect()
cat("after valid-record filter:",sum(cnt$n),"\n"); print(cnt)
