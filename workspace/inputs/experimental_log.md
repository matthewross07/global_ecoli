# Experimental Log

## 1. Experimental Setup

* **Datasets:** We compiled a global freshwater fecal indicator bacteria (FIB)
  database from ten public sources — nine point-observation networks plus one
  annual-summary source. The nine point-observation networks were the US Water
  Quality Portal (WQP), the European Environment Agency Eionet bathing-water
  reporting system, the UN GEMS/Water GEMStat release, DataStream (Canada),
  the UK Environment Agency Water Quality Archive (Open WIMS), South Africa's
  National Microbial Monitoring Programme (NMMP), France's Hub'Eau/Naïades API,
  New Zealand's LAWA, and the Water Point Data Exchange (WPdx). Brazil's ANA was
  available only as annual summary statistics and was held in a separate table.

* **Quantities computed (metrics):** For every record we tracked source,
  country, indicator type, water-body (ecosystem) class, latitude/longitude,
  date, and concentration in CFU per 100 mL. From these we computed: per-source
  and per-region record counts and shares; indicator composition; ecosystem
  composition; per-site observation counts; per-site median consecutive
  sampling gap and mean return interval; and, for recreational safety, the
  fraction of samples at or below 235 CFU per 100 mL (the safe threshold used
  throughout).

* **Comparison points:** We compared regional shares computed on the full
  all-water cleaned record against shares computed on the freshwater-only
  subset; we compared per-site sampling cadence against management-relevant
  bands (daily, weekly, monthly, quarterly, yearly, longer); and we compared
  the safety behavior of three high-frequency case-study sites on three
  continents over a single year.

* **Implementation details (harmonization pipeline):** All concentrations were
  standardized to CFU per 100 mL; MPN values were treated as CFU as an
  approximation, and qPCR-equivalent and non-convertible units were dropped.
  Censored values recorded a direction (left-censored were filled at one half
  the lower detection limit; right-censored at the upper limit). Location
  descriptors were mapped to a controlled vocabulary. Duplicate observations
  were averaged within each source and then de-duplicated across sources using
  a fuzzy key with roughly 1 km coordinate tolerance. Each record was then
  classified as marine, groundwater, or freshwater: marine was flagged by
  location type (ocean or estuary) or by the bathing-water category fields C
  (coastal) and T (transitional), which overrode an ambiguous location type;
  groundwater was excluded as a distinct exposure pathway. Records lacking both
  a usable location type and a bathing-water category were dropped as not
  verifiably inland. High-frequency sites were defined as those with a median
  consecutive sampling gap of at most 3 days and at least 30 samples.

## 2. Raw Numeric Data

Per-source freshwater contributions:

| Source | Region | Freshwater observations | Access |
| --- | --- | --- | --- |
| WQP | United States | 3,321,490 | API |
| Eionet | EU / EEA | 763,440 | Web scrape + XML/GML |
| GEMStat | Global (excluding US) | 399,706 | Manual (curated release) |
| DataStream | Canada | 296,913 | API |
| UK Open WIMS | United Kingdom | 189,485 | REST API |
| NMMP | South Africa | 161,467 | Manual CSV |
| Hub'Eau | France | 146,650 | API |
| LAWA | New Zealand | 35,248 | Manual Excel |
| WPdx | Global water points | 392 | Manual CSV |
| ANA (annual summaries) | Brazil | 14,853 | Manual CSV (separate annual table) |

Record reduction through the pipeline:

| Stage | Records |
| --- | --- |
| Harmonized (all water types) | 9,055,019 |
| Cleaned (valid indicator, date, coordinates, value) | 9,044,108 |
| Marine removed | 3,409,529 |
| Groundwater removed | 26,284 |
| Other/unknown reclassified via bathing-water category | 212,554 |
| Other/unknown dropped as not verifiably inland | 293,504 |
| Final freshwater analysis dataset | 5,314,791 |

Geographic distribution of the freshwater dataset:

| Region | Records | Share |
| --- | --- | --- |
| United States | 3,342,758 | 62.9% |
| Europe | 1,099,575 | 20.7% |
| Canada | 305,432 | 5.7% |
| Rest of world | 567,026 | 10.7% |

Leading rest-of-world contributors were Mexico (256,461), South Africa
(161,467), India (106,143), New Zealand (35,248), and Uruguay (7,331).

Indicator composition of the freshwater dataset:

| Indicator | Records | Share |
| --- | --- | --- |
| Escherichia coli | 2,308,643 | 43.4% |
| Fecal coliform | 1,692,665 | 31.8% |
| Total coliform | 560,355 | 10.5% |
| Intestinal enterococci | 479,053 | 9.0% |
| Fecal streptococcus group | 274,075 | 5.2% |

Ecosystem composition of the freshwater dataset:

| Ecosystem | Records | Share |
| --- | --- | --- |
| River / stream | 3,848,418 | 72.4% |
| Lake | 1,199,766 | 22.6% |
| Reservoir | 109,751 | 2.1% |
| Canal | 101,042 | 1.9% |
| Ditch | 19,397 | 0.4% |
| Spring | 19,094 | 0.4% |
| Wetland | 14,482 | 0.3% |
| Pond | 2,841 | 0.1% |

Distribution of per-site sampling return intervals among the 116,489 sites with
at least two samples (the full dataset contained 133,328 distinct sites; 10.8%
of sites had at least 100 observations and only 0.7% had at least 500):

| Return interval band | Share of multi-sample sites |
| --- | --- |
| Daily (≤ 1.5 days) | 7.0% |
| Weekly (1.5–8 days) | 9.1% |
| Monthly (8–31 days) | 29.9% |
| Quarterly (31–92 days) | 30.7% |
| Yearly (92–366 days) | 19.2% |
| Longer (> 366 days) | 4.2% |

High-frequency safety summary: across 631 high-frequency sites comprising
235,398 *E. coli* samples, 77.6% of samples were at or below 235 CFU per 100 mL
(safe) and 22.4% exceeded it.

High-frequency case studies, year 2023:

| Site | Country | Samples | Exceedance (> 235) | Median | Maximum |
| --- | --- | --- | --- | --- | --- |
| Euclid Beach | United States | 128 | 18.0% | 41 | 2,420 |
| River Lune | United Kingdom | 43 | 83.7% | 580 | 100,000 |
| Taruheru River | New Zealand | 40 | 62.5% | 465 | 11,000 |

## 3. Qualitative Observations

* The freshwater dataset was dominated by a small number of regions: the United
  States, Europe, and Canada together accounted for 89.3% of records, leaving
  10.7% for the rest of the world.
* Restricting to freshwater raised the relative rest-of-world share compared
  with the all-water record, because Europe's contribution was heavily coastal
  bathing-water data that was removed.
* An earlier all-water tabulation that attributed roughly 98% of records to the
  United States plus Europe and Canada was traced to attributing the globally
  sourced GEMStat records to Europe; the corrected freshwater shares were 62.9%,
  20.7%, and 5.7% respectively.
* No single indicator dominated; *E. coli* was the most common at 43.4%.
  Coverage of non–*E. coli* indicators was uneven across sources, and intestinal
  enterococci came almost entirely from European inland bathing waters.
* Marine and coastal bathing waters were excluded by design, so the marine
  indicator enterococci was out of scope rather than a coverage gap.
* High-frequency monitoring was almost exclusively located in North America and
  Europe, with only a few sites in South Africa and New Zealand.
* Among high-frequency sites, exceedance rates varied widely: many sites were
  consistently safe while a substantial minority in agricultural or urban
  catchments showed chronic exceedance above 20%.
* The three high-frequency case-study sites behaved very differently in 2023.
  The United States beach was safe most of the time (18.0% exceedance) and
  showed short-lived spikes that recovered within days, whereas the United
  Kingdom and New Zealand river sites were above the safe threshold for the
  majority of the year (83.7% and 62.5% exceedance), indicating chronic rather
  than transient contamination.
* Brazil's ANA published only annual summary statistics publicly even though
  sub-annual sampling demonstrably existed, an example of the data sharing
  barrier rather than absent monitoring.
* Several known sources were excluded for documented reasons, including
  Australia (access wall), China (monthly aggregates only), and pre-2006
  European bathing water (compliance classes rather than concentrations).
* Datetimes and time zones were not globally harmonized, and the MPN-to-CFU
  treatment was an approximation; both were noted as limitations.
