# Methods Digest — Global FIB Monitoring Dataset

> Reference backbone for the Methods section, distilled from the data-acquisition
> pipeline (`OpenCurrentLLC/wqual_pipeline`, local: `/home/mike/git/opencurrent/pipeline`).
> Ground truth = the `source` column of `data/harmonized/harmonized.feather`
> (9,055,019 records) and `data/harmonized/harmonized_annual.feather` (14,853 records).
> Companion file: `data_sources_summary.csv` (machine-readable source inventory).
> **Format: outline, for hand-off to paperorchestra — not finished prose.**

---

## M1. Dataset overview

- Final product: two harmonized feather tables produced by `src/final_harmonize.R`.
  - `harmonized.feather` — 9,055,019 individual observations, 9 sources, 17 columns
    (date, time_local, var, val, site_id, lat, lon, state, loc_type, BWCat, unit,
    orig_unit, org, method, censor_side, source, USGSpcode).
  - `harmonized_annual.feather` — 14,853 records, **ANA (Brazil) only**, annual
    summary schema (year, var, min, max, med, …) — kept separate because the source
    publishes only annual aggregates, not point observations.
- All concentrations standardized to **CFU/100 mL**; original unit retained in `orig_unit`.
- 9 point-observation sources + 1 annual-summary source (ANA) actually reached the final data.

## M2. Source contributions (point observations)

| Source | Records | Geography | Acquisition |
|---|--:|---|---|
| WQP | 4,901,716 | United States | API (`dataRetrieval`) |
| Eionet | 2,448,202 | EU/EEA | CDR web scrape + XML/GML |
| UK Open WIMS | 495,119 | United Kingdom | REST API |
| GEMStat | 412,067 | Global (ex-US) | Manual (Zenodo) |
| DataStream | 403,952 | Canada | API (`datastreamr`) |
| NMMP | 167,521 | South Africa | Manual CSV |
| Hub'Eau | 151,723 | France | API (`hubeau`) |
| LAWA | 67,129 | New Zealand | Manual Excel |
| WPdx | 7,590 | Global water points | Manual CSV |
| **ANA (annual)** | 14,853 | Brazil | Manual CSV (annual only) |

- **Geographic concentration:** US (WQP) + Europe/Canada (Eionet, UK, Hub'Eau, DataStream)
  dominate; this is the empirical basis for the paper's "collection gap vs. sharing gap" thesis.

## M3. Per-source acquisition (one sub-section each in Methods)

- **WQP (US Water Quality Portal).** `dataRetrieval::readWQPdata`, `ResultWQX3` service,
  "narrow" profile; water/surface-water/estuary media; 11 FIB characteristic names
  (`cfg/wqp_vars.txt`). Large states chunked by county to dodge rate limits; retry-on-error.
- **Eionet (EEA Bathing Water Directive).** Scrape of Eionet CDR reporting envelopes; parse
  XML monitoring/identified-site files + GML geometry. E. coli + intestinal enterococci.
  Post-2000 only (concentrations ~2006+).
- **UK Open WIMS.** Environment Agency Water Quality Archive REST API
  (`environment.data.gov.uk/water-quality`), paged, filtered by determinand codes.
  E. coli, fecal/total coliform, enterococci. 2000–present. (Legacy `uk_bwq` filenames.)
- **GEMStat (UN GEMS/Water).** Manual download of curated Zenodo release (record 14230628),
  assembled basin-by-basin globally; **USA deliberately excluded** (WQP covers it).
- **DataStream (Canada).** `datastreamr` API + free key; chunked by region/year; 1970–present.
  Closes the "Canada missing" gap flagged in early project notes.
- **NMMP (South Africa).** Manual government CSVs (National Microbial Monitoring Programme);
  merged "surface water sites" + "hotspots". E. coli + fecal coliform.
- **Hub'Eau (France / Naïades).** `hubeau` API, year/month chunked (20k-row cap); 1971–present.
  E. coli + coliforms (enterococci available but not pulled).
- **LAWA (New Zealand).** Manual Excel download (CC BY 4.0). Automated per-council Hilltop
  retrieval abandoned — see M6.
- **WPdx (Water Point Data Exchange).** Manual bulk CSV; only the fecal-coliform-bearing
  subset (7,590 of millions of points) retained.
- **ANA (Brazil, annual).** Manual CSV of pre-aggregated annual stats (min/max/median per
  station-year) → `harmonized_annual.feather`. Sub-annual API unavailable (M6).

## M4. Harmonization (`final_harmonize.R` + `helpers.R`)

- **Unit standardization** (`standardize_ecoli_units`): everything → CFU/100 mL via volume
  multipliers; **MPN treated as CFU** (approximation, flagged); **qPCR equivalents dropped**;
  mass/turbidity/ppm and other non-convertible units dropped.
- **Detection limits / censoring** (`apply_detection_limits`): left-censored → 0.5 × lower DL;
  right-censored → upper DL; direction recorded in `censor_side`; contradictory metadata blocks
  imputation.
- **Location typing** (`loc_type`): per-source strings mapped to a controlled vocabulary
  (river/stream, lake, ocean, estuary, canal, ditch, spring, pond, wetland, reservoir,
  groundwater/well, other).
- **Within-source dedup:** average `val` across identical (var, date, site, lat, lon, time, …).
- **Cross-source dedup:** fuzzy key = `date | var | round(val,1) | round(lat,2) | round(lon,2)`
  (~1 km tolerance); keep the row with the most complete metadata. Catches the same sample
  reported by multiple portals under different site IDs.
- **State backfill:** WQP→"USA", DataStream→"Canada" when state missing.

## M5. Indicators / variables

- FIB variables harmonized across sources: **E. coli, fecal coliform, total coliform,
  intestinal enterococci, fecal streptococcus**, plus rare WQP-only types (E. coli O157, EHEC,
  Bacteroidetes). Cleaning rules in this repo's `clean_data.R` define the canonical keep-list.

## M6. Excluded sources & data gaps (Limitations / Discussion)

Full inventory with reasons in `data_sources_summary.csv`. Highlights:

- **Excluded — known reason:**
  - *ANA full/sub-annual (Brazil):* SNIRH/HIDROWEB Telemetria API deprecated + access-walled
    (HTTP 500; new API requires registration) and serves only hydrology, not water quality →
    only annual aggregate survives.
  - *Australia (Queensland WMIP / KiWIS):* access wall; no national portal → Australia absent.
  - *LAWA automated retrieval:* 15 of 16 council Hilltop endpoints failed → manual Excel used
    (data still included).
  - *Waterbase (EEA WISE):* exploratory/dead code, superseded by Eionet; produces no rows.
  - *EEA pre-2006 bathing water:* only compliance classes (not concentrations), coliforms not
    E. coli, not digitized pre-2006.
  - *China (ESSD):* monthly averages, FC-only, aggregated → absent (sharing gap).
  - *India (CPCB NWMP):* access wall + monthly averages + minimal E. coli → only a GEMStat slice.
- **Excluded — unknown/undocumented reason (future candidates):** Colombia (IDEAM RNMCA),
  APMP Water Quality Database — listed as candidates in the project `todo`, never pursued.
- **Known methodological caveats** (carry into Limitations):
  - MPN→CFU equivalence is approximate.
  - Datetimes/timezones not globally harmonized; some `time_local` missing (kept as local).
  - WQP records lacking standardized lat/lon are dropped (lossy).
  - ~1 km cross-source dedup tolerance may merge distinct nearby sites or miss true duplicates.
  - "Sharing gap": Russia/China and much of the Global South effectively absent despite likely
    national networks.

## M7. Open items / to verify before drafting

- Confirm whether ANA annual data is used in the paper's headline counts or held aside (schema
  differs — no individual obs).
- Decide how WPdx (water-point, mostly developing-country, fecal-coliform-only) is framed —
  small N but fills a geographic void.
- Per-source temporal coverage table (start years above are approximate) if a temporal figure
  is needed.
