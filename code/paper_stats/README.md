# Reported-statistics provenance

Code and data reproducing the numbers in the manuscript. During drafting, much
of this analysis lived in throwaway scripts under `/tmp`; it is collected here so
the paper is reproducible and archivable. Run everything from **`code/`**, e.g.
`Rscript paper_stats/equity_correlation.R`.

Input and output locations come from `../paths.R`, whose defaults resolve to the
repo root one level above `code/` — that is where `fecal_indicators_clean.feather`
lives and where outputs are written. See `../../CODE_OCEAN.md` for the Code Ocean
capsule, which overrides them to read from `/data` and write to `/results`.

## Verified, clean, reproduce-from-feather scripts

| Script | Paper location | Key numbers |
|---|---|---|
| `../make_figures.R` | Figs 1–4 | ecosystem/indicator density, cadence survival + interval distribution, high-frequency map + donuts + case studies |
| `../make_fig5_downsampling.R` | Fig 5, §3.6, **Table S1** | monthly 15.2% (8.3 FS / 7.0 FU), weekly 11.2%, quarterly 16.2%; transitional 21.2%; year-round & chronic asymmetry (writes `table_s1_asymmetry.csv`) |
| `equity_correlation.R` | §3.2 | 52 countries with open freshwater data; Spearman ρ = −0.71 (p = 5×10⁻⁹); 94 countries ≥ median WASH mortality, 73 (78%) absent; 17 of 20 highest-burden absent |
| `record_cascade.R` | Methods | 11,151,268 harmonized → 11,136,805 after validity filter; 26,496 groundwater excluded → 11,110,309 surface (5,899,783 freshwater 53.1%, 5,210,526 marine 46.9%) |
| `geography_table.R` | §3.1, Table 2 | US 6,926,157 (62.3%), Europe 3,165,984 (28.5%), Canada 412,450 (3.7%), RoW 605,718 (5.5%); ~21,000 GEMStat U.S. records (footnote) |
| `south_africa.R` | §3.7 | NMMP 167,336 obs; 1,566 well-sampled E. coli sites; median per-site geomean 182 CFU/100 mL; 20% >1,000; 32-day median cadence |
| `temporal_coverage.R` | Results "Temporal coverage of the record", Table 4, §3.3 provenance sentence, Abstract | span 1950–2026; median year 2013; 87.1% / 67.4% / 43.8% from 2000 / 2010 / 2015; per-source first and last year; fecal coliform 81% WQP median 2007, total coliform 75% WQP median 2010, fecal streptococci 92% WQP median 1986 |
| `cadence_highfreq.R` | §3.4, §3.5, Table 3, Fig 4 caption | 198,296 sites, 13.5% ≥100 obs, 1.7% ≥500; 164,566 multi-sample sites, 0.9% daily, 0.6% near-daily, 48.2% monthly, 24.7% quarterly; ~80% of timed records 08:00–14:00, ~80% Mon–Wed, 3% weekend, 1% 17:00–23:00; 374 near-daily sites (181 fresh / 193 marine), 95.2% US, 18 elsewhere; 129,832 fresh samples 89.4% ≤410, 162,615 marine samples 82.7% ≤130; case-study exceedance 44.7 / 6.7 / 24.0 / 97.3% |
| `compliance_criteria.R` | Results "Compliance assessed as the criteria are written", Limitations, Methods | 30-day test at near-daily site-years: fresh E. coli 62.1% fail (GM 34.3%, STV 61.4%; n=560), marine enterococci 76.4% (54.0%, 75.9%; n=755); calendar-year test: fresh 46.1% (n=69,102), marine 16.3% (n=96,285); near-daily fresh annual 37.0% vs 30-day 62.1%; WHO category A 40.5%, >200 25.1% (n=119,437) |

The composition table (§3.3) is intentionally left for readers to recompute: it is a
plain group-by on the archived feather, and its only definitional choices (indicator
classing, ecosystem grouping) already live in `../clean_data.R`.

### Correction applied via `geography_table.R`
An earlier draft of Table 2 binned **Albania (4,260) and Montenegro (1,826) into
"Rest of world"** rather than Europe, though both are European Adriatic
bathing-water countries. This was corrected (2026-07-02): they are now in Europe,
giving Europe 3,165,984 (28.5%) and RoW 605,718 (5.5%), matching `main.tex` Table 2.
The 6,086-record shift changes no conclusion.

## data/

- `pop.csv` — UN World Population Prospects national population (`undesa_wpp`).
- `wash.csv` — WHO GHO mortality attributable to unsafe WASH, SDG 3.9.2 (`who_gho_wash`).
- `fw_sites_by_country.csv` — freshwater sites per country. Cached copy for
  reference; `equity_correlation.R` rebuilds it from the feather on every run and
  writes the fresh copy to the output directory (repo root by default,
  `/results` in the capsule).

**Provenance note:** an unsafe-water-only mortality series (`uw.csv`) was explored
but is *not* used — that OWID chart is non-redistributable and returns HTTP 403.
All §3.2 numbers use `wash.csv` (full WASH mortality), via `final2.R` / `equity_correlation.R`.

## scratch/

Verbatim drafting scripts, preserved for provenance. Unpolished; some read `/tmp`
intermediates from the drafting session and may need a path tweak to rerun. Mapping
to the paper (by what each computes):

- `density.R`, `final2.R`, `spearman.R` — §3.2 equity correlation (**superseded by `equity_correlation.R`**; `final2.R` was the canonical version, `spearman.R` an earlier iteration).
- `cascade.R` — Methods record cascade (**superseded by `record_cascade.R`**).
- `mstats.R`, `sw_full_recount.R` — §3.1 geography (**superseded by `geography_table.R`**) plus the §3.3 composition table (left for readers).
- `sa.R`, `sa_year.R`, `sa_scout.R` — §3.7 South Africa / NMMP (**superseded by `south_africa.R`**; `sa_scout.R`/`sa_year.R` retained for site-level detail).
- `distinct_day.R`, `genuine2.R`, `hf_diag.R` — §3.5 genuine near-daily site selection and counts (374 sites, US share, realm-specific safe fractions; **superseded by `cadence_highfreq.R`**, and also reproduced by `../make_figures.R`).
- `fig3num.R` — §3.4 sampling-cadence statistics (**superseded by `cadence_highfreq.R`**).
- `case_lock.R`, `canada_yr.R` — §3.5 case-study site selection (Gisborne, Alberta, Marina del Rey, Devon); the Table 3 exceedance rates are now printed by `cadence_highfreq.R`.
- `wi3.R` — Fig 2 Wisconsin site selection.
- `euro_marine_scout.R` — European marine coverage scouting.
