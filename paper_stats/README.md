# Reported-statistics provenance

Code and data reproducing the numbers in the manuscript. During drafting, much
of this analysis lived in throwaway scripts under `/tmp`; it is collected here so
the paper is reproducible and archivable. Run everything from the **repo root**
(where `fecal_indicators_clean.feather` lives), e.g. `Rscript paper_stats/equity_correlation.R`.

## Verified, clean, reproduce-from-feather scripts

| Script | Paper location | Key numbers |
|---|---|---|
| `../make_figures.R` | Figs 1–4 | ecosystem/indicator density, cadence survival + interval distribution, high-frequency map + donuts + case studies |
| `../make_fig5_downsampling.R` | Fig 5, §3.6, **Table S1** | monthly 15.2% (8.3 FS / 7.0 FU), weekly 11.2%, quarterly 16.2%; transitional 21.2%; year-round & chronic asymmetry (writes `table_s1_asymmetry.csv`) |
| `equity_correlation.R` | §3.2 | 52 countries with open freshwater data; Spearman ρ = −0.71 (p = 5×10⁻⁹); 94 countries ≥ median WASH mortality, 73 (78%) absent; 17 of 20 highest-burden absent |

## data/

- `pop.csv` — UN World Population Prospects national population (`undesa_wpp`).
- `wash.csv` — WHO GHO mortality attributable to unsafe WASH, SDG 3.9.2 (`who_gho_wash`).
- `fw_sites_by_country.csv` — freshwater sites per country, rebuilt by `equity_correlation.R`.

**Provenance note:** an unsafe-water-only mortality series (`uw.csv`) was explored
but is *not* used — that OWID chart is non-redistributable and returns HTTP 403.
All §3.2 numbers use `wash.csv` (full WASH mortality), via `final2.R` / `equity_correlation.R`.

## scratch/

Verbatim drafting scripts, preserved for provenance. Unpolished; some read `/tmp`
intermediates from the drafting session and may need a path tweak to rerun. Mapping
to the paper (by what each computes):

- `density.R`, `final2.R`, `spearman.R` — §3.2 equity correlation (folded into `equity_correlation.R`; `final2.R` is the canonical version, `spearman.R` an earlier iteration).
- `cascade.R` — Methods record cascade: harmonized → valid-record filter → realm split (freshwater/marine/groundwater counts).
- `mstats.R`, `sw_full_recount.R` — §3.1 geography table (country shares) and §3.3 indicator/ecosystem composition table.
- `sa.R`, `sa_year.R`, `sa_scout.R` — §3.7 South Africa / NMMP (record count, well-sampled site count, geometric-mean concentrations, monthly cadence).
- `distinct_day.R`, `genuine2.R`, `hf_diag.R` — §3.5 genuine near-daily site selection and counts (374 sites, US share, realm-specific safe fractions).
- `fig3num.R` — §3.4 sampling-cadence statistics (site counts, retention percentages, multi-sample interval distribution).
- `case_lock.R`, `canada_yr.R` — §3.5 case-study site selection (Gisborne, Alberta, Marina del Rey, Devon).
- `wi3.R` — Fig 2 Wisconsin site selection.
- `euro_marine_scout.R` — European marine coverage scouting.
