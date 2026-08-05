#!/usr/bin/env bash
# Code Ocean capsule entrypoint.
#
# Reproduces every figure and every reported statistic in the manuscript,
# starting from the cleaned surface-water dataset. Code Ocean runs this from
# /code with the capsule's data mounted read-only at /data; outputs go to
# /results, one log per step alongside the figures.
#
# The defaults below are the capsule's layout, so running this script on a
# workstation means pointing it at local directories. From code/, e.g.
#
#   FIB_IN_DIR=.. FIB_OUT_DIR=../out ./reproduce.sh
#
# The individual R scripts, by contrast, need no environment at all: their
# defaults resolve to the repo root, one level above code/. See CODE_OCEAN.md.
set -euo pipefail

cd "$(dirname "$0")"

# Capsule layout by default; override any of these to run elsewhere.
export FIB_IN_DIR="${FIB_IN_DIR:-/data}"
export FIB_OUT_DIR="${FIB_OUT_DIR:-/results}"
export FIB_HARMONIZED="${FIB_HARMONIZED:-/data/harmonized.feather}"
export FIB_CACHE="${FIB_CACHE:-/tmp/cache_nearlydaily.rds}"

CLEAN_FEATHER="$FIB_IN_DIR/fecal_indicators_clean.feather"

mkdir -p "$FIB_OUT_DIR"

if [[ ! -f "$CLEAN_FEATHER" ]]; then
  echo "ERROR: cannot find $CLEAN_FEATHER" >&2
  echo "Attach the 'fecal_indicators_clean' data asset to this capsule, or set" >&2
  echo "FIB_IN_DIR to the directory holding fecal_indicators_clean.feather." >&2
  exit 1
fi

run_step () {
  local label="$1"; shift
  echo
  echo "=================================================================="
  echo "== $label"
  echo "=================================================================="
  "$@" 2>&1 | tee "$FIB_OUT_DIR/log_${label}.txt"
}

# Record the exact environment the results were produced in.
Rscript -e 'writeLines(capture.output(sessionInfo()))' > "$FIB_OUT_DIR/log_sessionInfo.txt" 2>&1

# ---- Reported statistics (Results 3.1, 3.2, 3.7) ----
run_step geography_table    Rscript paper_stats/geography_table.R
run_step equity_correlation Rscript paper_stats/equity_correlation.R
run_step south_africa       Rscript paper_stats/south_africa.R

# ---- Figures 1-4 (Results 3.1, 3.4, 3.5) ----
run_step make_figures Rscript make_figures.R

# ---- Figure 5 + Table S1 (Results 3.6) ----
# Rebuilds the near-daily site-year cache from scratch; the slowest step.
run_step make_fig5_downsampling Rscript make_fig5_downsampling.R

# ---- Steps needing the 2.2 GB harmonized database ----
# The Methods record cascade counts records at each filtering stage, so it reads
# the pre-cleaning database rather than the cleaned feather. Attach the
# 'harmonized' data asset to enable it; without it the rest still reproduces.
if [[ -f "$FIB_HARMONIZED" ]]; then
  run_step record_cascade Rscript paper_stats/record_cascade.R

  # Regenerating the cleaned feather from the harmonized database is off by
  # default: it writes a 600 MB file into /results and every other step above
  # already consumes the archived copy. Set FIB_RUN_CLEAN=1 to verify the
  # cleaning step end to end.
  if [[ "${FIB_RUN_CLEAN:-0}" == "1" ]]; then
    run_step clean_data Rscript clean_data.R
  fi
else
  echo
  echo "NOTE: $FIB_HARMONIZED not found; skipping paper_stats/record_cascade.R." >&2
  echo "      Attach the 'harmonized' data asset to reproduce the Methods record cascade." >&2
fi

echo
echo "Done. Outputs written to $FIB_OUT_DIR:"
ls -la "$FIB_OUT_DIR"
