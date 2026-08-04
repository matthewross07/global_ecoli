# global_ecoli

Cleaning, analysis, figures, and reported statistics for *"Eleven Million
Measurements, Two Blind Spots: The State of Global Surface-Water Fecal Indicator
Monitoring."*

This repository is the **analysis half** of the paper and is packaged as a
[Code Ocean](https://codeocean.com) capsule, so that pressing *Reproduce Run*
regenerates every figure and every reported number from the archived data without
installing anything. See [`CODE_OCEAN.md`](CODE_OCEAN.md) for capsule setup and
data assets.

The work spans two repositories, split at the harmonized database:

| Stage | Repository | In the capsule |
|---|---|---|
| Retrieval and harmonization of 11.1 M records from 9 public sources | `OpenCurrentLLC/wqual_pipeline` | No — cited by DOI in the Code Availability statement |
| Cleaning, analysis, figures, reported statistics | **this repository** | Yes |

The pipeline is excluded from the capsule deliberately: its inputs are ~149 GB of
raw downloads from the nine source agencies, which is both too large for a capsule
and already public at the source.

## Quick start

Everything runs **from the repository root**, and needs one input file that is not
in git (see [Data](#data)):

```sh
# the whole reproducible run, writing to ./out
FIB_IN_DIR=. FIB_OUT_DIR=./out ./run.sh

# or one piece at a time, using the defaults in paths.R
Rscript make_figures.R
Rscript paper_stats/equity_correlation.R
```

Scripts under `paper_stats/` `source("paths.R")` relative to the repository root,
so invoke them as `Rscript paper_stats/<script>.R` — not from inside the
directory.

`paths.R` parameterizes every location through environment variables, which is
what lets the same scripts run locally and in the capsule:

| Variable | Local default | Capsule |
|---|---|---|
| `FIB_IN_DIR` | `.` | `/data` |
| `FIB_OUT_DIR` | `.` | `/results` |
| `FIB_HARMONIZED` | `../../pipeline/data/harmonized/harmonized.feather` | `/data/harmonized.feather` |
| `FIB_CACHE` | `.cache_nearlydaily.rds` | `/tmp/cache_nearlydaily.rds` |

The defaults reproduce the original local layout: cleaned feather in the root,
outputs written beside it.

## Data

Two Feather files, both gitignored — Code Ocean caps the git side at 1 GB total
and 100 MB per file, while data assets allow 5 GB per file.

**`fecal_indicators_clean.feather`** (~600 MB) is the analysis dataset: the
11,110,309 surface-water records surviving cleaning, each tagged `freshwater` or
`marine`. Required by everything. Available as the capsule's
`fecal_indicators_clean` data asset, or regenerate it with `clean_data.R`.

**`harmonized.feather`** (2.2 GB) is the pre-cleaning database from
`wqual_pipeline`, needed only by `clean_data.R` and `paper_stats/record_cascade.R`.
The cascade counts records that cleaning *removes*, so they cannot be recovered
from the cleaned file. Optional; `run.sh` skips both scripts with a note if it is
absent.

## Scripts

| Script | Produces |
|---|---|
| `clean_data.R` | `fecal_indicators_clean.feather` from the harmonized database |
| `make_figures.R` | Figures 1–4 |
| `make_fig5_downsampling.R` | Figure 5 and `table_s1_asymmetry.csv` (§3.6) |
| `paper_stats/geography_table.R` | §3.1 and Table 2 |
| `paper_stats/equity_correlation.R` | §3.2, and `fw_sites_by_country.csv` |
| `paper_stats/south_africa.R` | §3.7 |
| `paper_stats/record_cascade.R` | the Methods record cascade |
| `paths.R` | path configuration, sourced by all of the above |
| `run.sh` | the capsule entrypoint: runs the six analysis scripts, teeing a log per step |

`clean_data.R` restricts to five canonical indicator classes (*E. coli*, fecal
coliform, total coliform, enterococci, fecal streptococcus), applies date,
coordinate, and value-range filters, standardizes country names, assigns each
record a `realm` — marine if the location type is ocean or estuary or the Eionet
bathing-water category is coastal or transitional, groundwater if the location
type says so, freshwater otherwise — and drops groundwater. It is the only script
that writes the cleaned feather, which is why `run.sh` places it *last* and
behind an opt-in flag (`FIB_RUN_CLEAN=1`): the cleaned file is archived as a data
asset, so a normal run consumes it rather than rebuilding it.

Figures 4 and 5 both depend on the "genuine near-daily" site-year definition: at
least 30 distinct sampling days in a year from 2018 on, with a median gap between
distinct sampling days of 3 days or less. Thresholds throughout are 410
CFU/100 mL for freshwater and 130 for marine.

## Reported-statistics provenance

[`paper_stats/README.md`](paper_stats/README.md) maps every number in the
manuscript to the script that produces it, and is the place to look when checking
a specific claim. Two things it documents are worth surfacing here:

- The §3.3 composition table is **intentionally** left for readers to recompute —
  it is a plain group-by on the archived feather, and its only definitional
  choices already live in `clean_data.R`.
- A correction is recorded against Table 2: an earlier draft binned Albania and
  Montenegro into "rest of world." Both are now counted in Europe. The
  6,086-record shift changes no conclusion, and the corrected 31-country Europe
  vector is written out explicitly in `geography_table.R`.

`paper_stats/scratch/` holds the 18 original drafting scripts, kept under version
control for provenance but **not part of the reproducible run** — several read
`/tmp` intermediates from the drafting session and will not run unmodified.
`paper_stats/README.md` maps each to the script that replaced it.

`paper_stats/data/` holds the two external series used in §3.2: national
population (UN World Population Prospects) and mortality attributable to unsafe
WASH (WHO GHO, SDG 3.9.2), both for 2019.

## Outputs

Committed at the repository root as a reference for comparison:
`fig1_surface_distribution.png` through `fig5_downsampling.png`, and
`table_s1_asymmetry.csv`.

A run regenerates those, plus `fw_sites_by_country.csv`, `log_sessionInfo.txt`,
and one `log_<step>.txt` per step. Table 2 and the §3.1, §3.2, §3.7, and Methods
numbers are printed to stdout and captured in those logs rather than written as
files.

## Environment

`environment/Dockerfile` records what the analysis needs: R 4.6.1 on
`rocker/r-ver`, GDAL/PROJ/GEOS/udunits system libraries for `sf`, and thirteen R
packages. It also asserts at build time that the `rnaturalearth` medium-scale
basemap loads, so the run needs no network access. Package versions used for the
submitted figures are listed in the file's header.

Code Ocean maintains its own environment through the capsule's Environment tab;
this file is the reconciliation reference, and `log_sessionInfo.txt` in the
results is ground truth for any published run.

Note that `workspace/` contains an earlier manuscript-drafting apparatus (an AGU
LaTeX template, bibliography, caption tooling) that predates the marine expansion
and the current title. It is unrelated to the capsule and to everything described
above.

## License and AI use

Code is MIT-licensed; see [`LICENSE`](LICENSE). Use of AI-assisted coding tools is
disclosed in [`AI_USE.md`](AI_USE.md).
