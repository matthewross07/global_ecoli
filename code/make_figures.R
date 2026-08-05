# Surface-water manuscript figures (Fig 1, Fig 3, merged Fig 4).
# Reads fecal_indicators_clean.feather (all surface waters, with `realm`).
suppressMessages({
  library(arrow); library(dplyr); library(data.table)
  library(ggplot2); library(sf); library(patchwork); library(scales)
})

theme_pub <- function(base = 11) {
  theme_minimal(base_size = base) +
    theme(plot.title = element_text(face = "bold", size = base + 1, color = "#1a1a1a"),
          plot.subtitle = element_text(size = base - 1, color = "#5f5f5f"),
          axis.title = element_text(size = base - 1, color = "#444444"),
          axis.text = element_text(color = "#444444"),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_line(color = "grey92"))
}
source("paths.R")

FRESH_THR <- 410; MARINE_THR <- 130
d <- read_feather(fib_in("fecal_indicators_clean.feather"), as_data_frame = FALSE)

## ---------------- FIG 1: global density + ecosystem inset ----------------
eco <- d %>% select(loc_type, lat, lon) %>% filter(!is.na(lat) & !is.na(lon)) %>% collect()
eco$class <- dplyr::case_when(
  eco$loc_type == "ocean" ~ "Ocean",
  eco$loc_type %in% c("river/stream","canal","ditch","spring") ~ "River/Stream",
  eco$loc_type %in% c("lake","reservoir","pond","wetland") ~ "Lake",
  eco$loc_type == "estuary" ~ "Estuary",
  TRUE ~ "Other")
# The basemap is taken straight from the rnaturalearthdata data package rather
# than through rnaturalearth::ne_countries(scale = "medium"). The two return the
# same object -- 242 features, 169 columns, identical geometry and CRS -- but
# rnaturalearth imports terra, and terra requires GDAL >= 3.8 to compile, which
# Ubuntu 22.04 (GDAL 3.4.1) cannot provide. Going direct drops both packages and
# needs no compilation at all. Do not substitute countries110 (coarser) or
# countries10 (in rnaturalearthhires, not on CRAN).
world_robin <- st_transform(st_as_sf(rnaturalearthdata::countries50), crs = "+proj=robin")
pc <- sf_project(from = "+proj=longlat +datum=WGS84", to = "+proj=robin",
                 pts = as.matrix(eco[, c("lon","lat")]))
proj_df <- data.frame(x = pc[,1], y = pc[,2])
p_map1 <- ggplot() +
  geom_sf(data = world_robin, fill = "#eceff1", color = "#cfd8dc", linewidth = 0.12) +
  geom_hex(data = proj_df, aes(x = x, y = y), bins = 175) +
  scale_fill_viridis_c(option = "mako", direction = -1, trans = "log10",
                       labels = scales::comma, name = "Observations per hex (log scale)") +
  guides(fill = guide_colorbar(barwidth = 14, barheight = 0.5, title.position = "top", title.hjust = 0.5)) +
  theme_void(base_size = 11) +
  labs(title = "Global Surface-Water Fecal Indicator Bacteria Data Density",
       subtitle = "Severe geographic disparities driven by both monitoring infrastructure and public data sharing") +
  theme(plot.title = element_text(face="bold", size=15, hjust=0.5, color="#1a1a1a"),
        plot.subtitle = element_text(size=11, hjust=0.5, color="#5f5f5f", margin=margin(b=6)),
        legend.position = "bottom", legend.title = element_text(size=9, color="#444444"),
        plot.margin = margin(8,8,8,8))
eco_inset <- as.data.table(eco)[class != "Other", .N, by = class]
eco_inset[, lbl := paste0(round(N/1e6, 2), "M")]
p_eco <- ggplot(eco_inset, aes(x = reorder(class, N), y = N/1e6)) +
  geom_col(width = 0.72, fill = "#3182bd", show.legend = FALSE) +
  geom_text(aes(label = lbl), hjust = -0.12, size = 2.8, color = "#2d2d2d") +
  coord_flip(clip = "off") + expand_limits(y = max(eco_inset$N/1e6)*1.18) +
  labs(title = "Observations by ecosystem", x = NULL, y = NULL) +
  theme_minimal(base_size = 9) +
  theme(panel.grid = element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank(),
        axis.text.y = element_text(size = 8, color = "#2d2d2d"),
        plot.title = element_text(face="bold", size=8, color="#2d2d2d"),
        plot.background = element_rect(fill = "white", color = "grey75", linewidth = 0.4),
        plot.margin = margin(5,7,5,5))
fig1 <- p_map1 + inset_element(p_eco, left = 0.015, bottom = 0.13, right = 0.33, top = 0.35)
ggsave(fib_out("fig1_surface_distribution.png"), fig1, width = 12, height = 5.6, dpi = 300)
cat("fig1 done\n")

## ---------------- FIG 2: sampling-cadence mismatch (Wisconsin, 2022) ----------------
# Same indicator (E. coli), state, and year; three monitoring designs differing in
# cadence. Map (A) on the left; objective-labeled time series (B-D) stacked on the right.
wi_sites <- data.table(
  lab = c("B","C","D"),
  id  = c("WIDNR_WQX-133331","WIDNR_WQX-283220","WIDNR_WQX-413640"),
  lat = c(42.972,43.188,43.100), lon = c(-89.229,-88.726,-87.909))
neigh <- as.data.table(map_data("state",
   region=c("wisconsin","minnesota","iowa","illinois","michigan","indiana")))
p_loc <- ggplot() +
  geom_polygon(data=neigh, aes(long,lat,group=group), fill="#f3f4f6", color="#ffffff", linewidth=0.4) +
  geom_polygon(data=neigh[region=="wisconsin"], aes(long,lat,group=group),
               fill="#e3edf5", color="#90a4ae", linewidth=0.5) +
  geom_point(data=wi_sites, aes(lon,lat), size=3, color="#333333") +
  ggrepel::geom_text_repel(data=wi_sites, aes(lon,lat,label=lab), fontface="bold", size=4.6,
     box.padding=0.7, point.padding=0.4, min.segment.length=0, segment.color="grey25", seed=3) +
  coord_quickmap(xlim=c(-93,-86.5), ylim=c(42,47.2)) + theme_void(base_size=11) +
  labs(title="A) Wisconsin, USA monitoring sites") +
  theme(plot.title=element_text(face="bold", size=12, hjust=0.5, color="#1a1a1a"))
fig2_panel <- function(lab, id, objective, yr=2022, thr=FRESH_THR, ylab=NULL, show_x=FALSE) {
  x <- d %>% filter(site_id==id, var=="Escherichia coli") %>% select(date,val) %>% collect(); setDT(x)
  x <- x[as.integer(format(date,"%Y"))==yr][, .(val=max(val)), by=date][order(date)]
  jan <- as.Date(sprintf("%d-01-01",yr)); dec <- as.Date(sprintf("%d-12-31",yr))
  g <- ggplot(x, aes(date, val)) +
    annotate("rect", xmin=jan, xmax=dec, ymin=1, ymax=thr, fill="#0072B2", alpha=0.07) +
    geom_hline(data=data.frame(y=thr), aes(yintercept=y, linetype="410 CFU/100 mL (EPA 2012 freshwater threshold)"),
               color="#E69F00", linewidth=0.7) +
    geom_line(color="grey75", linewidth=0.3) +
    geom_point(aes(color=val>thr), size=1.9) +
    scale_color_manual(values=c("FALSE"="#0072B2","TRUE"="#E69F00"),
                       labels=c("FALSE"="At or below threshold","TRUE"="Above threshold"), name=NULL) +
    scale_linetype_manual(values=c("410 CFU/100 mL (EPA 2012 freshwater threshold)"="dashed"), name=NULL) +
    scale_y_log10(breaks=10^(0:4), labels=scales::comma, limits=c(1,25000)) +
    scale_x_date(limits=c(jan,dec), breaks=as.Date(sprintf("%d-%02d-01",yr,1:12)),
                 labels=c("J","F","M","A","M","J","J","A","S","O","N","D"), expand=expansion(mult=0.01)) +
    theme_pub(10) + theme(plot.title=element_text(size=10), legend.position="bottom") +
    labs(title=sprintf("%s) %s", lab, objective), x=NULL, y=ylab)
  if (!show_x) g <- g + theme(axis.text.x=element_blank())
  g
}
g2B <- fig2_panel("B","WIDNR_WQX-133331","Swimming (daily req.)")
g2C <- fig2_panel("C","WIDNR_WQX-283220","Regulatory (monthly)", ylab="E. coli (CFU/100 mL)")
g2D <- fig2_panel("D","WIDNR_WQX-413640","Long-term trend (quarterly)", show_x=TRUE)
header <- ggplot() + theme_void() +
  labs(title="E. coli observations by monitoring objective, 2022") +
  theme(plot.title=element_text(face="bold", size=11, hjust=0.5, color="#1a1a1a"))
right_col <- header / g2B / g2C / g2D + plot_layout(heights=c(0.12,1,1,1))
fig2 <- (p_loc | right_col) + plot_layout(widths=c(1.0,1.3), guides="collect") &
  theme(legend.position="bottom")
ggsave(fib_out("fig2_cadence_mismatch.png"), fig2, width=11.5, height=6.5, dpi=300)
cat("fig2 done\n")

## ---------------- FIG 3: actionability gap ----------------
ss <- d %>% select(site_id, lat, lon, date) %>% collect(); setDT(ss)
ss[, sk := fifelse(is.na(site_id), paste0("c_",round(lat,4),"_",round(lon,4)), site_id)]
site <- ss[, .(n=.N), by=sk]                                    # data volume (panel A)
thr <- c(1,2,5,10,20,50,100,250,500,1000)
surv <- data.frame(t=thr, pct=sapply(thr, function(z) 100*mean(site$n>=z)))
p_surv <- ggplot(surv, aes(factor(t), pct, group=1)) +
  geom_area(fill="#3182bd", alpha=0.12) + geom_line(color="#3182bd", linewidth=1.1) +
  geom_point(color="#08519c", size=2.6) +
  geom_text(aes(label=paste0(round(pct),"%")), hjust=-0.3, vjust=-0.4, size=2.8, color="#08519c") +
  expand_limits(y=108) + theme_pub(11) +
  labs(title="A) Site Data Volume Survival Curve", x="Minimum Observations per Site", y="Percentage of Sites (%)")
cad <- unique(ss[, .(sk, date)])[order(sk,date), .(nd=.N, medgap=as.numeric(median(diff(date)))), by=sk][nd>=2]
lv <- c("Daily\n(0, 1]","Near-daily\n(1, 3]","Weekly\n(3, 7]","Monthly\n(7, 31]",
        "Quarterly\n(31, 92]","Yearly\n(92, 366]","Longer\n(> 366)")
cad[, band := factor(fcase(medgap<=1,lv[1], medgap<=3,lv[2], medgap<=7,lv[3], medgap<=31,lv[4],
   medgap<=92,lv[5], medgap<=366,lv[6], default=lv[7]), levels=lv)]
idf <- cad[, .(pct=round(100*.N/nrow(cad),1)), by=band]
idf[, hl := ifelse(band %in% lv[1:2], "hi", "Other")]
p_int <- ggplot(idf, aes(band, pct, fill=hl)) +
  geom_col(width=0.72, show.legend=FALSE) +
  geom_text(aes(label=paste0(pct,"%")), vjust=-0.4, size=3, color="#2d2d2d") +
  scale_fill_manual(values=c("hi"="#d7301f","Other"="#74a9cf")) +
  expand_limits(y=max(idf$pct)*1.13) + theme_pub(11) + theme(panel.grid.major.x=element_blank()) +
  labs(title="B) Distribution of Sampling Return Intervals", x="Median sampling interval (days)", y="Percentage of Multi-Sample Sites (%)")
ggsave(fib_out("fig3_actionability.png"), p_surv + p_int, width = 12, height = 6, dpi = 300)
cat("fig3 done\n")

## ---------------- FIG 4 (merged): hi-freq map + donut + 2x2 cases ----------------
# High-frequency = GENUINE near-daily: >=30 distinct sampling DAYS with distinct-day
# median gap <=3 d, in at least one year >= 2018. Only E. coli (fresh)/enterococci (marine).
hf_year <- function(realm_sel, var_sel, thr) {
  x <- d %>% filter(realm==realm_sel, var==var_sel) %>% select(site_id,lat,lon,date,val) %>% collect(); setDT(x)
  x[, `:=`(sk=fifelse(is.na(site_id),paste0("c_",round(lat,4),"_",round(lon,4)),site_id), yr=as.integer(format(date,"%Y")))]
  dd <- x[, .(v=mean(val)), by=.(sk,yr,date)]
  sy <- dd[order(sk,date), .(days=.N, dg=as.numeric(median(diff(date)))), by=.(sk,yr)]
  keep <- unique(sy[yr>=2018 & days>=30 & !is.na(dg) & dg<=3, sk])
  pool <- x[sk %in% keep]
  sites <- pool[, .(lat=first(lat), lon=first(lon), exceed=100*mean(val>thr)), by=sk]
  list(sites=sites, pool=pool)
}
fw <- hf_year("freshwater","Escherichia coli",FRESH_THR)
mr <- hf_year("marine","Enterococci",MARINE_THR)
fw_safe <- round(100*mean(fw$pool$val<=FRESH_THR),1); mr_safe <- round(100*mean(mr$pool$val<=MARINE_THR),1)
cat(sprintf("FIG4 genuine near-daily sites: fresh=%d marine=%d | donut safe: fresh=%.1f%% marine=%.1f%%\n",
    nrow(fw$sites), nrow(mr$sites), fw_safe, mr_safe))
hfs <- rbind(fw$sites, mr$sites)
hp <- sf_project(from="+proj=longlat +datum=WGS84", to="+proj=robin", pts=as.matrix(hfs[,.(lon,lat)]))
hfs[, `:=`(x=hp[,1], y=hp[,2])]
# case sites are already in the cloud; manual leaders + labels (no separate markers)
cases <- data.table(
  lab=c("A","B","C","D"),
  lat=c(-38.661,53.528,33.980,50.612), lon=c(178.033,-113.499,-118.458,-3.400),
  ldx=c(-1.7e6,-1.8e6,-1.6e6,-2.8e6), ldy=c(1.2e6,0.3e6,-1.3e6,0), lh=c(1,1,1,1))
cp <- sf_project(from="+proj=longlat +datum=WGS84", to="+proj=robin", pts=as.matrix(cases[,.(lon,lat)]))
cases[, `:=`(x=cp[,1], y=cp[,2], lx=cp[,1]+ldx, ly=cp[,2]+ldy)]
p_hfmap <- ggplot() +
  geom_sf(data=world_robin, fill="#f3f4f6", color="#ffffff", linewidth=0.15) +
  geom_point(data=hfs, aes(x=x, y=y, color=pmin(exceed,100)), size=1.4, alpha=0.85) +
  scale_color_viridis_c(option="viridis", limits=c(0,100), name="% samples\nexceeding") +
  geom_segment(data=cases, aes(x=x, y=y, xend=lx, yend=ly), color="grey15", linewidth=0.4) +
  geom_text(data=cases, aes(x=lx, y=ly, label=lab, hjust=lh), vjust=0.5, fontface="bold", size=4.4, color="black") +
  coord_sf(ylim=c(-6e6, 8.6e6), expand=FALSE) + theme_void(base_size=11) +
  labs(title="Genuine near-daily monitoring sites (points) and case studies (A–D)") +
  theme(plot.title=element_text(face="bold", size=12, color="#1a1a1a"), legend.position="right",
        legend.title=element_text(size=8), legend.key.height=unit(0.8,"cm"))
donut_df <- data.table(
  realm=factor(rep(c("Freshwater\n(E. coli, threshold\n410 CFU/100mL)","Marine\n(enterococci, threshold\n130 CFU/100mL)"), each=2),
               levels=c("Freshwater\n(E. coli, threshold\n410 CFU/100mL)","Marine\n(enterococci, threshold\n130 CFU/100mL)")),
  Status=rep(c("Safe","Unsafe"),2), pct=c(fw_safe,100-fw_safe,mr_safe,100-mr_safe))
p_donut <- ggplot(donut_df, aes(x=2, y=pct, fill=Status)) +
  geom_col(width=1, color="white") + coord_polar(theta="y") + xlim(c(0.3,2.5)) +
  facet_wrap(~realm, ncol=1) +
  geom_text(data=donut_df[Status=="Safe"], aes(x=0.3, y=0, label=paste0(pct,"%")), size=4, fontface="bold", color="#0072B2") +
  scale_fill_manual(values=c("Safe"="#0072B2","Unsafe"="#E69F00"), name=NULL) +
  theme_void(base_size=10) + labs(title="Safety summary") +
  theme(plot.title=element_text(face="bold", size=12, hjust=0.5, color="#1a1a1a"),
        strip.text=element_text(size=8.5, face="bold"), legend.position="bottom")
case_panel <- function(lab, id, var_sel, thr, yr, place, country, wtype, ylab, show_x) {
  x <- d %>% filter(site_id==id, var==var_sel) %>% select(date,val) %>% collect(); setDT(x)
  x <- x[as.integer(format(date,"%Y"))==yr][, .(val=max(val)), by=date][order(date)]   # collapse same-day replicates
  jan <- as.Date(sprintf("%d-01-01",yr)); dec <- as.Date(sprintf("%d-12-31",yr))
  g <- ggplot(x, aes(date, val)) +
    annotate("rect", xmin=jan, xmax=dec, ymin=1, ymax=thr, fill="#0072B2", alpha=0.07) +
    geom_hline(yintercept=thr, linetype="dashed", color="#E69F00", linewidth=0.7) +
    geom_line(color="grey75", linewidth=0.3) +
    geom_point(aes(color=val>thr), size=1.5) +
    scale_color_manual(values=c("FALSE"="#0072B2","TRUE"="#E69F00")) +
    scale_y_log10(breaks=10^(0:6), labels=scales::comma) +
    scale_x_date(limits=c(jan,dec), breaks=as.Date(sprintf("%d-%02d-01",yr,1:12)),
                 labels=c("J","F","M","A","M","J","J","A","S","O","N","D"), expand=expansion(mult=0.01)) +
    theme_pub(10) + theme(legend.position="none", plot.title=element_text(size=9.5)) +
    labs(title=sprintf("%s) %s, %s (%d; %s)", lab, place, country, yr, wtype), x=NULL, y=ylab)
  if (!show_x) g <- g + theme(axis.text.x=element_blank())
  g
}
EC <- "E. coli (CFU/100mL)"; ENT <- "Enterococci (CFU/100mL)"
pA <- case_panel("A","lawa_lawa-102417","Escherichia coli",FRESH_THR,2020,"Gisborne","New Zealand","river",EC,FALSE)
pB <- case_panel("B","datastream_804997","Escherichia coli",FRESH_THR,2023,"Alberta","Canada","river",NULL,FALSE)
pC <- case_panel("C","CABEACH_WQX-MDRH-1","Enterococci",MARINE_THR,2024,"Marina del Rey","USA","coast",ENT,TRUE)
pD <- case_panel("D","uk_bwq_SW-70511008","Enterococci",MARINE_THR,2024,"Devon","UK","coast",NULL,TRUE)
top <- p_hfmap + p_donut + plot_layout(widths=c(2.2,1.15))
grid <- (pA | pB) / (pC | pD)
fig4 <- top / grid + plot_layout(heights=c(1.0,1.5))
ggsave(fib_out("fig4_highfreq_cases.png"), fig4, width=12, height=11, dpi=300)
cat("fig4 done\n")
