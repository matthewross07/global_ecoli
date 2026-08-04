# Code Ocean capsule

This repository is the analysis half of the manuscript *"Eleven Million
Measurements, Two Blind Spots: The State of Global Surface-Water Fecal Indicator
Monitoring."* It is packaged as a Code Ocean capsule so reviewers can reproduce
every figure and every reported statistic without installing anything.

Pressing **Reproduce Run** executes `run.sh`, which regenerates Figures 1–5,
Table S1, and the numbers quoted in Results 3.1, 3.2, 3.6, and 3.7, writing all
of them plus a per-step log to `/results`.

## What is and is not in the capsule

The work spans two code repositories, split at the harmonized database:

| Stage | Where it lives | In the capsule? |
|---|---|---|
| Acquisition and harmonization of 11.1 M records from 9 public sources | `OpenCurrentLLC/wqual_pipeline` | No — cited, see below |
| Cleaning, analysis, figures, reported statistics | this repository | Yes |

The acquisition pipeline is excluded deliberately. Its inputs are roughly 149 GB
of raw downloads from the nine source agencies, which is both too large for a
capsule and already public at the source. The capsule therefore begins at the
harmonized database, and the pipeline is cited separately by DOI in the
manuscript's Code Availability statement.

## Data assets

Two data assets back the capsule. Attach them in the capsule's **Data** tab; both
mount read-only under `/data`.

| Asset | File | Size | Needed for |
|---|---|---|---|
| `fecal_indicators_clean` | `/data/fecal_indicators_clean.feather` | 600 MB | everything — **required** |
| `harmonized` | `/data/harmonized.feather` | 2.2 GB | `paper_stats/record_cascade.R` — optional |

`fecal_indicators_clean.feather` is the surface-water analysis dataset: all
11,110,309 records that survive cleaning, each tagged `freshwater` or `marine`.
It is produced by `clean_data.R` from the harmonized database.

`harmonized.feather` is the pre-cleaning database. It is only needed to
reproduce the Methods record cascade (the 11,151,268 → 11,136,805 → 11,110,309
counts), because those counts are of records that cleaning removes and so cannot
be recovered from the cleaned file. `run.sh` detects whether it is attached and
skips that one step if it is not; everything else still reproduces.

## Reproducible run

`run.sh` runs these steps in order, teeing each to `/results/log_<step>.txt`:

| Step | Reproduces |
|---|---|
| `paper_stats/geography_table.R` | Results 3.1, Table 2 — regional record counts |
| `paper_stats/equity_correlation.R` | Results 3.2 — Spearman ρ = −0.71, high-burden absence |
| `paper_stats/south_africa.R` | Results 3.7 — NMMP summary |
| `make_figures.R` | Figures 1–4 |
| `make_fig5_downsampling.R` | Figure 5 and Table S1 |
| `paper_stats/record_cascade.R` | Methods record cascade (needs `harmonized`) |

`make_fig5_downsampling.R` is the slow step: it rebuilds the near-daily
site-year ground truth from the full dataset before simulating the coarser
monitoring regimes. It caches that intermediate at `$FIB_CACHE`, which defaults
to `/tmp` inside the capsule so each reproducible run recomputes it from the
archived data rather than trusting a stored artifact.

Regenerating the cleaned feather itself is off by default, since it writes a
600 MB file to `/results` and needs the `harmonized` asset. Set `FIB_RUN_CLEAN=1`
to include `clean_data.R` and verify the cleaning step end to end.

`/results/log_sessionInfo.txt` records the R and package versions each run
actually used.

## Running outside the capsule

The scripts resolve their paths through `paths.R`, whose defaults reproduce the
original local layout — the cleaned feather in the repo root, outputs written
beside it. So from the repo root:

```sh
Rscript make_figures.R
Rscript paper_stats/equity_correlation.R
```

behaves exactly as it did before the capsule existed. Four environment variables
override the defaults, and `run.sh` sets all of them to the capsule layout:

| Variable | Local default | Capsule |
|---|---|---|
| `FIB_IN_DIR` | `.` | `/data` |
| `FIB_OUT_DIR` | `.` | `/results` |
| `FIB_HARMONIZED` | `../../pipeline/data/harmonized/harmonized.feather` | `/data/harmonized.feather` |
| `FIB_CACHE` | `.cache_nearlydaily.rds` | `/tmp/cache_nearlydaily.rds` |

Run scripts from the repo root either way; `paper_stats/` scripts source
`paths.R` relative to it.

## `paper_stats/scratch/`

Verbatim drafting scripts, kept for provenance and superseded by the polished
scripts above. They are **not** part of the reproducible run: several read `/tmp`
intermediates from the original drafting session and will not run unmodified.
`paper_stats/README.md` maps each one to the script that replaced it.

## Building the capsule

1. **Create the capsule from this repo.** In Code Ocean, *New Capsule →  Clone
   from Git*, using this repository's HTTPS URL. Cloning (rather than importing)
   keeps the link, so later commits reach the capsule through *Check for
   updates* and capsule-side commits push back via *Sync with GitHub*. A private
   repo needs a GitHub access token registered in your Code Ocean account.
2. **Set up the environment.** In the *Environment* tab pick an R 4.6 base image
   and add the packages listed in `environment/Dockerfile`. `sf` and `arrow` are
   the two that make container builds slow or awkward; Code Ocean's support
   staff will help here, and the service is free to authors.
3. **Attach the data.** Upload `fecal_indicators_clean.feather` as a data asset,
   and `harmonized.feather` as a second one if you want the record cascade.
   Both stay out of git — Code Ocean caps the git side at 1 GB total and 100 MB
   per file, while data assets allow 5 GB per file.
4. **Verify.** Press *Reproduce Run* and check `/results` against the figures
   committed at the repo root and the numbers tabulated in
   `paper_stats/README.md`.
5. **Link the manuscript.** In the capsule's *Metadata* tab, select the
   manuscript under *Associated Publication*, and set the license to MIT to
   match `LICENSE`.

## Licensing and AI use

The code here is MIT-licensed; see `LICENSE`. Use of AI-assisted coding tools is
disclosed in `AI_USE.md`, which is the repository-level counterpart to the
statement in the manuscript's Methods section.
