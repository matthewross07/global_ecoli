# Figure 5 + temporal down-sampling analysis of advisory error.
#
# Treats every genuine near-daily site-year as ground truth, simulates coarser
# monitoring regimes (daily -> quarterly), and scores how often the resulting
# single-sample advisory would be wrong (false-safe / false-unsafe). Also tests
# whether the false-safe asymmetry survives at year-round and at chronically
# contaminated sites (backs the asymmetry claim in Results 3.6).
#
# Reproduces the reported figures: monthly 15.2% (8.3% FS + 7.0% FU),
# weekly 11.2%, quarterly 16.2% (estuaries excluded; 1,308 site-years), and
# 21.2% at transitional sites. Renders fig5_downsampling.png.
#
# Consolidated from the exploratory scripts used during drafting
# (downsample.R, diag_gm.R, seasontest.R, fig5b.R, fig5_final.R).
suppressMessages({
  library(arrow); library(dplyr); library(data.table); library(lubridate)
  library(ggplot2); library(patchwork); library(scales)
})

theme_pub <- function(b = 11) theme_minimal(base_size = b) +
  theme(plot.title = element_text(face = "bold", size = b + 1, color = "#1a1a1a"),
        axis.title = element_text(size = b - 1, color = "#444444"),
        axis.text = element_text(color = "#444444"),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "grey92"))

FRESH_THR <- 410; MARINE_THR <- 130          # single-sample (STV) thresholds
FRESH_GM  <- 126; MARINE_GM  <- 35           # 30-day geometric-mean criteria (sensitivity)
CACHE <- ".cache_nearlydaily.rds"            # derived; safe to delete (gitignored)

## ---------------- Build near-daily site-years (ground truth) ----------------
# Per site-year, collapse same-day replicates to a daily geometric mean, then
# keep GENUINE near-daily years: >=30 distinct sampling days with distinct-day
# median gap <=3 d, in a recent year (>=2018). Fresh = E. coli, marine = entero.
build_realm <- function(rl, vv, thr) {
  d <- read_feather("fecal_indicators_clean.feather", as_data_frame = FALSE)
  x <- d %>% filter(realm == rl, var == vv) %>%
    select(site_id, lat, lon, loc_type, date, val) %>% collect(); setDT(x)
  x[, sk := fifelse(is.na(site_id), paste0("c_", round(lat, 4), "_", round(lon, 4)), site_id)]
  x[, yr := year(date)]
  dd <- x[, .(v = exp(mean(log(pmax(val, 1)))), loc = first(loc_type)), by = .(sk, yr, date)]
  q <- dd[order(sk, date), .(days = .N, mg = as.numeric(median(diff(date)))), by = .(sk, yr)][
    yr >= 2018 & days >= 30 & mg <= 3]
  dd[, ky := paste(sk, yr)]; q[, ky := paste(sk, yr)]
  out <- dd[ky %in% q$ky]; out[, `:=`(realm = rl, thr = thr)]; out
}
if (file.exists(CACHE)) {
  S <- readRDS(CACHE)
} else {
  S <- rbind(build_realm("freshwater", "Escherichia coli", FRESH_THR),
             build_realm("marine", "Enterococci", MARINE_THR))
  saveRDS(S, CACHE)
}
S[, loc_grp := fcase(loc %in% c("river/stream", "canal", "ditch", "spring"), "river",
                     loc %in% c("lake", "reservoir", "pond", "wetland"), "lake",
                     loc == "ocean", "ocean", loc == "estuary", "estuary", default = "other")]
S[, gthr := fifelse(realm == "freshwater", FRESH_GM, MARINE_GM)]

## ---------------- Simulation core ----------------
# snap(): map each scheduled day to the nearest real observation within tol.
snap <- function(sched, di, tol) {
  n <- length(di); j <- findInterval(sched, di, all.inside = TRUE); jr <- pmin(j + 1L, n)
  jj <- ifelse(abs(di[j] - sched) <= abs(di[jr] - sched), j, jr)
  jj <- jj[abs(di[jj] - sched) <= tol]; unique(jj)
}
# sim_ss(): single-sample advisory. For each phase offset of the schedule, post
# the sampled day's binary state as a standing advisory until the next sample,
# score against the true daily state, and average false-safe / false-unsafe
# rates over all phase offsets.
sim_ss <- function(di, st, interval) {
  span <- max(di); tol <- interval / 2; maxph <- min(interval - 1L, span)
  phases <- unique(as.integer(round(seq(0, maxph, length.out = min(maxph + 1L, 31L)))))
  fs <- fu <- numeric(length(phases))
  for (i in seq_along(phases)) {
    p <- phases[i]; sched <- if (p >= span) p else seq(p, span, by = interval)
    si <- snap(sched, di, tol); if (!length(si)) { fs[i] <- NA; fu[i] <- NA; next }
    o <- order(di[si]); sd <- di[si][o]; ssg <- st[si][o]
    pos <- findInterval(di, sd); has <- pos >= 1L; adv <- ssg[pmax(pos, 1L)]
    fs[i] <- mean(adv[has] == 0 & st[has] == 1); fu[i] <- mean(adv[has] == 1 & st[has] == 0)
  }
  c(fs = mean(fs, na.rm = TRUE), fu = mean(fu, na.rm = TRUE))
}

## ---------------- Per-site-year results (weekly / monthly / quarterly) ----------------
regs <- c(weekly = 7L, monthly = 30L, quarterly = 91L); keys <- unique(S$ky)
res <- rbindlist(lapply(keys, function(k) {
  z <- S[ky == k][order(date)]
  di <- as.integer(z$date - min(z$date)); st <- as.integer(z$v > z$thr[1])
  r <- data.table(syk = k, realm = z$realm[1], loc_grp = z$loc_grp[1],
                  days = nrow(z), span = max(di), exc = mean(st), cross = sum(abs(diff(st))))
  for (nm in names(regs)) {
    rr <- sim_ss(di, st, regs[[nm]])
    r[[paste0("fs_", nm)]] <- rr["fs"]; r[[paste0("fu_", nm)]] <- rr["fu"]
  }
  r
}))
res[, vol := fcase(exc < 0.05, "stable-safe", exc > 0.95, "stable-unsafe", default = "transitional")]

# Headline rates exclude the 13 estuary site-years (small sample), matching the paper.
noest <- res[loc_grp != "estuary"]
rate <- function(dt, nm) 100 * c(fs = mean(dt[[paste0("fs_", nm)]], na.rm = TRUE),
                                 fu = mean(dt[[paste0("fu_", nm)]], na.rm = TRUE))

cat("\n=== near-daily site-years:", nrow(res), "(estuary-excluded:", nrow(noest), ") ===\n")
print(res[, .N, by = realm]); print(noest[, .N, by = realm])
cat("\n=== HEADLINE advisory error (estuary-excluded) ===\n")
for (nm in names(regs)) {
  a <- rate(noest, nm); cat(sprintf("  %-9s  false-safe %.1f  false-unsafe %.1f  total %.1f\n",
                                    nm, a["fs"], a["fu"], a["fs"] + a["fu"]))
}
cat("\n=== transitional sites only (fluctuate across threshold) ===\n")
for (nm in names(regs)) {
  a <- rate(res[vol == "transitional"], nm)
  cat(sprintf("  %-9s  total %.1f\n", nm, a["fs"] + a["fu"]))
}

## ---------------- Asymmetry breakdowns -> Supporting Information Table S1 ----------------
# The false-safe asymmetry is not an artifact of seasonal windows or contamination
# level: it persists and strengthens (a) at chronically contaminated sites and
# (b) at year-round sites. Emit both breakdowns as one reproducible table.
noest[, contam := fcase(exc < 0.05, "Rarely exceeds (<5%)", exc < 0.5, "Intermittent (5-50%)",
                        exc < 0.95, "Frequent (50-95%)", default = "Chronic (>95%)")]
noest[, seas := fcase(span <= 170, "Seasonal (<=170 d)", span >= 300, "Year-round (>=300 d)",
                      default = "Mid (170-300 d)")]
strata_rows <- function(col, order_levels) {
  rbindlist(lapply(order_levels, function(lv) {
    d <- noest[get(col) == lv]; if (!nrow(d)) return(NULL)
    r <- data.table(group = col, level = lv, n = nrow(d))
    for (nm in names(regs)) {
      a <- rate(d, nm)
      r[[paste0(nm, "_FS")]] <- round(a["fs"], 1); r[[paste0(nm, "_FU")]] <- round(a["fu"], 1)
      r[[paste0(nm, "_diff")]] <- round(a["fs"] - a["fu"], 1)
    }
    r
  }))
}
tblS1 <- rbind(
  strata_rows("contam", c("Rarely exceeds (<5%)", "Intermittent (5-50%)", "Frequent (50-95%)", "Chronic (>95%)")),
  strata_rows("seas", c("Seasonal (<=170 d)", "Mid (170-300 d)", "Year-round (>=300 d)")))
fwrite(tblS1, "table_s1_asymmetry.csv")
cat("\n=== ASYMMETRY breakdown (Table S1; FS/FU/diff, % of monitored days) ===\n")
print(tblS1)

## ---------------- Panel B curve: error vs sampling interval (1-91 d) ----------------
Tgrid <- c(1, 2, 3, 4, 5, 7, 10, 14, 21, 30, 45, 60, 75, 91)
rr <- rbindlist(lapply(noest$syk, function(k) {
  z <- S[ky == k][order(date)]
  di <- as.integer(z$date - min(z$date)); st <- as.integer(z$v > z$thr[1])
  rbindlist(lapply(Tgrid, function(T) { b <- sim_ss(di, st, T); data.table(T = T, fs = b["fs"], fu = b["fu"]) }))
}))
ag <- rr[, .(FSm = 100 * mean(fs), FSlo = 100 * quantile(fs, .25), FShi = 100 * quantile(fs, .75),
             FUm = 100 * mean(fu), FUlo = 100 * quantile(fu, .25), FUhi = 100 * quantile(fu, .75)),
         by = T][order(T)]
cat("\n=== interval curve (near-daily ~3d, weekly 7d, monthly 30d) ===\n")
for (i in seq_len(nrow(ag))) cat(sprintf("  %2dd  FS %.1f  FU %.1f  total %.1f\n",
                                          ag$T[i], ag$FSm[i], ag$FUm[i], ag$FSm[i] + ag$FUm[i]))

CB <- c("False-safe" = "#D55E00", "False-unsafe" = "#0072B2")
long <- rbind(ag[, .(T, type = "False-safe", m = FSm, lo = FSlo, hi = FShi)],
              ag[, .(T, type = "False-unsafe", m = FUm, lo = FUlo, hi = FUhi)])
labpos <- merge(data.table(T = c(1, 3, 7, 30, 91),
                           name = c("daily", "near-daily", "weekly", "monthly", "quarterly")),
                ag[, .(T, FSm)], by = "T"); labpos[, y := FSm + 1.4]
pB <- ggplot(long, aes(T, m, color = type, fill = type)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.10, color = NA) + geom_line(linewidth = 1) +
  geom_point(data = long[T %in% c(1, 3, 7, 30, 91)], size = 2.4) +
  geom_text(data = labpos, aes(T, y, label = name), inherit.aes = FALSE,
            hjust = 0, vjust = 0, size = 3, color = "grey30", angle = 28) +
  scale_color_manual(values = CB, name = NULL) + scale_fill_manual(values = CB, name = NULL) +
  scale_x_continuous(breaks = c(1, 7, 14, 30, 60, 91), expand = expansion(mult = c(0.02, 0.13))) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.10))) +
  labs(title = "B) Misadvised days rise with sampling interval",
       x = "Sampling interval (days)", y = "% of monitored days misadvised") +
  theme_pub(11) + theme(legend.position = "bottom")

## ---------------- Panel A: mechanism on one example site-year ----------------
# Pick a transitional, year-round, frequently-crossing site-year for illustration.
cand <- noest[exc > 0.18 & exc < 0.38 & span > 260 & cross >= 10][order(-cross)]
k <- cand$syk[1]
ex <- S[ky == k][order(date)]; di <- as.integer(ex$date - min(ex$date))
thr <- ex$thr[1]; d0 <- min(ex$date); st <- ex$v > thr
cat("\n=== Panel A example site-year:", k, "===\n")
sched <- seq(10, max(di), by = 30); si <- snap(sched, di, 15)
o <- order(di[si]); sd <- di[si][o]; ssg <- st[si][o]
pos <- findInterval(di, sd); has <- pos >= 1L; adv <- ssg[pmax(pos, 1L)]
seg <- data.table(x0 = sd, x1 = c(sd[-1], max(di)), adv = ssg)[, `:=`(da = d0 + x0, db = d0 + x1)]
ptdf <- data.table(date = ex$date, v = ex$v, has = has, adv = adv, st = st)[
  , cat := fcase(has & adv == FALSE & st == TRUE, "False-safe",
                 has & adv == TRUE & st == FALSE, "False-unsafe", default = "Correctly advised")]
sdf <- ptdf[date %in% (d0 + sd)][, cat := "Monthly grab sample"]
LV  <- c("Monthly grab sample", "False-safe", "False-unsafe", "Correctly advised")
colv <- c("False-safe" = "#D55E00", "False-unsafe" = "#0072B2",
          "Correctly advised" = "grey80", "Monthly grab sample" = "black")
shpv <- c("False-safe" = 16, "False-unsafe" = 16, "Correctly advised" = 16, "Monthly grab sample" = 18)
szv  <- c("False-safe" = 1.6, "False-unsafe" = 1.6, "Correctly advised" = 0.5, "Monthly grab sample" = 3)
pA <- ggplot() +
  geom_rect(data = seg, aes(xmin = da, xmax = db, ymin = 1, ymax = Inf, fill = adv), alpha = 0.13) +
  scale_fill_manual(values = c("FALSE" = "#0072B2", "TRUE" = "#D55E00"),
                    labels = c("open (safe)", "closed (unsafe)"), name = "Standing monthly advisory") +
  geom_hline(yintercept = thr, linetype = "dashed", color = "grey30") +
  geom_line(data = ptdf, aes(date, v), color = "grey80", linewidth = 0.25) +
  geom_point(data = ptdf, aes(date, v, color = cat, shape = cat, size = cat)) +
  geom_point(data = sdf, aes(date, v, color = cat, shape = cat, size = cat)) +
  scale_color_manual(values = colv, limits = LV, name = NULL) +
  scale_shape_manual(values = shpv, limits = LV, name = NULL) +
  scale_size_manual(values = szv, limits = LV, guide = "none") +
  scale_y_log10(labels = comma) + scale_x_date(date_labels = "%b") +
  labs(title = "A) One monthly schedule sampled from a near-daily record",
       x = NULL, y = "Enterococci (CFU/100 mL)") +
  theme_pub(11) + theme(legend.position = "bottom", legend.box = "vertical",
                        legend.key.height = unit(0.32, "cm")) +
  guides(color = guide_legend(order = 1, nrow = 1, override.aes = list(size = 2.6)),
         shape = guide_legend(order = 1, nrow = 1, override.aes = list(size = 2.6)),
         fill = guide_legend(order = 2))

ggsave("fig5_downsampling.png", pA + pB + plot_layout(widths = c(1.55, 1)),
       width = 13, height = 6, dpi = 300)
cat("\nfig5_downsampling.png written\n")
