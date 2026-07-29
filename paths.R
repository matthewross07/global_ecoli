# Input/output path resolution, shared by every analysis script in this repo.
#
# The defaults reproduce the original local layout exactly: the cleaned feather
# sits in the repo root, outputs are written to the repo root, and the
# harmonized database is a sibling checkout of the acquisition pipeline. So
# `Rscript make_figures.R` from the repo root behaves as it always has.
#
# The Code Ocean capsule overrides these via environment variables (see run.sh)
# because a capsule mounts inputs read-only at /data and requires outputs to be
# written to /results.
#
# Sourced from the repo root, including by scripts in paper_stats/.

# Directory holding fecal_indicators_clean.feather.
FIB_IN_DIR <- Sys.getenv("FIB_IN_DIR", unset = ".")

# Directory for figures, tables, and derived CSVs.
FIB_OUT_DIR <- Sys.getenv("FIB_OUT_DIR", unset = ".")

# The 2.2 GB harmonized database produced by the acquisition pipeline
# (github.com/OpenCurrentLLC/wqual_pipeline). Only clean_data.R and
# paper_stats/record_cascade.R need it; everything else starts from the
# cleaned feather.
FIB_HARMONIZED <- Sys.getenv(
  "FIB_HARMONIZED",
  unset = "../../pipeline/data/harmonized/harmonized.feather"
)

# Derived near-daily site-year cache for the down-sampling analysis. Rebuilt
# from the cleaned feather whenever it is absent, so a capsule run always
# recomputes it from scratch.
FIB_CACHE <- Sys.getenv("FIB_CACHE", unset = ".cache_nearlydaily.rds")

fib_in <- function(...) file.path(FIB_IN_DIR, ...)

fib_out <- function(...) {
  dir.create(FIB_OUT_DIR, recursive = TRUE, showWarnings = FALSE)
  file.path(FIB_OUT_DIR, ...)
}
