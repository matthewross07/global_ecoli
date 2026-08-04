suppressMessages({library(arrow); library(dplyr); library(data.table)})
d <- read_feather("fecal_indicators_clean.feather", as_data_frame=FALSE)
# (site_id, indicator, realm threshold)
cases <- list(
  list(id="179315",              ind="Escherichia coli", thr=410, lbl="South Africa (fresh)"),
  list(id="90234",               ind="Escherichia coli", thr=410, lbl="South Africa alt (fresh)"),
  list(id="lawa_gdc-00033",      ind="Escherichia coli", thr=410, lbl="Taruheru NZ (fresh)"),
  list(id="CABEACH_WQX-MDRH-1",  ind="Enterococci",      thr=130, lbl="Marina del Rey US (marine)"),
  list(id="uk_bwq_SW-81814942",  ind="Enterococci",      thr=130, lbl="UK Cornwall (marine)"),
  list(id="uk_bwq_NE-49000253",  ind="Enterococci",      thr=130, lbl="UK Yorkshire (marine)")
)
for (c in cases) {
  x <- d %>% filter(site_id==c$id, var==c$ind) %>% select(date,val,lat,lon) %>% collect()
  setDT(x); x[, yr:=as.integer(format(date,"%Y"))]
  cat(sprintf("\n=== %s  [%s, thr %d]  lat/lon: %.3f, %.3f ===\n", c$lbl, c$id, c$thr,
      x$lat[1], x$lon[1]))
  print(x[yr>=2021, .(n=.N, exceed=round(100*mean(val>c$thr),1), med=round(median(val)),
     max=round(max(val))), by=yr][order(yr)])
}
