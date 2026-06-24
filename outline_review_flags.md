# Outline Review Flags

Concise list of claims in `paper_outline.Rmd` that read **too authoritatively**, may be
**inaccurate**, or rest on **uneven data coverage** — with suggested defensive rewording.
Scope: the *existing* sections (Exec Summary, Figs 1–4, Discussion). The new **Methods**
section already incorporates these caveats. Severity: 🔴 fix before submission · 🟡 soften/verify · 🔵 minor/citation.

Ground-truth references: `country_summary.csv`, `states_summary.csv`, indicator×source
counts from `harmonized.feather`, and `methods_digest.md`.

---

## §1 Executive Summary & Core Thesis

- 🔴 **"54.3% US / 43.7% Europe & Canada" is wrong and now superseded.** Two problems:
  (1) The 43.7% was computed by **source**, mis-assigning the globally-sourced **GEMStat**
  records (India, Mexico, Uruguay…) to "Europe and Canada"; true all-water Europe+Canada is
  ~38.7%. (2) The paper is now **freshwater-focused**, so the operative numbers come from the
  freshwater dataset: **US ≈ 62.9%, Europe ≈ 20.7%, Canada ≈ 5.7%, RoW ≈ 10.7%** (≈89.3%
  combined). *Fix:* replace the Exec Summary figures with the freshwater shares (now in
  Methods M.5); note RoW is **larger** under the freshwater lens (coastal Europe drops out),
  so the "98%" framing erased a real Global-South tail.

- 🟡 **"our primary tool for protecting public health"** / **"FIB datasets"** framed as a
  comprehensive whole — narrow to **freshwater FIB**, where *E. coli* is the appropriate
  primary indicator. The compilation is E. coli–anchored; marine/coastal (enterococci-based)
  monitoring is **out of scope** by design, not missing data — say so rather than implying
  full coverage.

- 🟡 **"less than 6.1% of monitoring sites globally achieve daily or near-daily sampling"**
  — Figure 3 computes this over **multi-sample sites (n ≥ 2)**, not "sites globally."
  Single-observation sites are excluded from that denominator. *Fix:* align the denominator
  wording ("of sites with ≥2 samples") between Exec Summary and Fig 3. **Note:** on freshwater
  the value is now **7.0%**, so the "less than 6.1%" claim is no longer true.

- 🔵 **"absent from public, harmonized global repositories"** for Russia/China — defensible
  as stated, but pairs with the §5 "almost certainly" assertion (see Discussion).

## Figure 1 (Global Distribution & Ecosystem Footprint)

- 🟡 **Ecosystem record counts** (River 3.94 M, Ocean 2.82 M, Lake 1.17 M, Estuary 587 k)
  rest on a `case_when` that **conflates categories**: "River" absorbs canal/ditch/spring;
  "Lake" absorbs reservoir/pond/wetland; "Ocean"/"Estuary" partly keyed on `BWCat`. *Fix:*
  state these are **aggregated ecosystem classes**, and note the bins sum to <9.0 M (the
  remainder is Other/Unknown).

- 🟡 **"Ocean" totals are biased low** by the enterococci gap (marine indicator missing
  from WQP/Hub'Eau). Coastal/marine effort is **undercounted**, so the river-dominance
  story is partly an artifact of indicator selection. Flag in caption.

- 🔵 The Russia/China "visual void" claim is interpretive (sharing gap vs. true absence) —
  keep, but tie explicitly to the Discussion's hedged language.

## Figure 2 (Sampling Objectives & Mismatched Frequencies)

- 🟡 **Three named sites with assigned frequencies** (daily/monthly/quarterly) — verify
  each `site_id` actually exhibits the stated return interval in 2022–2023 before asserting
  it; these are illustrative anecdotes, not representative samples. *Soften:* "representative
  examples," not evidence of prevalence.

- 🔵 Thresholds/objectives mapping (daily=recreation, monthly=CWA compliance,
  quarterly=trend) is a useful framing but is an **assertion** — attribute or cite.

## Figure 3 (Quantifying the Actionability Gap)

- 🟡 **Site definition drives every number here.** Sites are keyed on `site_id` with a
  lat/lon fallback, after ~1 km cross-source de-duplication — this can **split or merge**
  true monitoring locations and shift the frequency distribution. *Add:* one sentence that
  the counts are sensitive to site definition.

- 🟡 **Mixed indicators per site** inflate apparent frequency: a site sampling E. coli
  *and* fecal coliform on different schedules is one "site" with pooled dates. *Verify*
  whether frequency is computed per indicator or pooled; state which.

- 🔴 **Fig 3 prose now disagrees with its own (live-recomputed) figure.** Fig 3 wasn't
  marine-broken so its code was left intact — but it recomputes on the freshwater
  `clean_data`, so the rendered figure now shows freshwater values while the prose still
  cites all-water numbers. Freshwater-correct values (133,328 sites; 116,489 multi-sample):
  **≥100 obs 10.8%** (was 11.8%), **≥500 obs 0.7%** (was 1.0%); **Daily 7.0%** (was 6.08%),
  Weekly 9.1%, **Monthly 29.9%** (was 35.4%), **Quarterly 30.7%** (was 27.0%), Yearly 19.2%,
  Longer 4.2%. *Fix:* update Fig 3's Key Findings to these.

## Figure 4 (Reclaiming Recreation Days)

- 🔴 **"safe 85% of the time" generalized from N = 36 daily E. coli sites.** Thirty-six
  sites is a tiny, geographically narrow base (likely US/EU-heavy) — too thin to support a
  *global* "even at high-monitoring sites" claim. *Fix:* present as a **case-study
  statistic from 36 high-frequency sites**, not a global safety rate; report where those
  sites are.

- 🟡 **"Safe (≤235 CFU)"** uses the **superseded 1986 EPA single-sample maximum**. Current
  US EPA 2012 recreational criteria use a geometric mean of **126** and a statistical
  threshold value of **410** CFU/100 mL for E. coli. *Fix:* pick and cite the intended
  standard; note it is indicator- and use-specific.

- 🟡 **"EU Bathing Limit (500)"** as a single dashed line oversimplifies. The EU Bathing
  Water Directive classifies on **95th/90th-percentile** bands (inland E. coli ≤500/≤1000;
  coastal ≤250/≤500) and treats **intestinal enterococci** as a co-equal/primary marine
  parameter. Zeebrugge is **coastal**, so 500 is not the clean single-sample limit implied.
  *Fix:* clarify it is a percentile-based classification boundary, not an action threshold.

- 🔵 Single-site case study (Zeebrugge 2008) is fine as illustration — label it as such,
  not as evidence that pollution is "transient" in general.

## §5 Discussion & Synthesis

- 🟡 **"almost certainly maintain national water quality networks"** (Russia/China) —
  unsupported certainty. *Soften:* "likely maintain," and cite known national programs if
  available (e.g., China MEE monitoring) to support the *sharing-gap* interpretation.

- 🔵 **Pathogen kinetics claims** — "spiking during rain events," "decaying within
  24–48 hours," "first flush" — domain-correct but **need citations** in the draft.

- 🔵 **"qPCR … to replace legacy 24-hour incubation"** — note we *dropped* qPCR records in
  harmonization, so the dataset cannot itself speak to qPCR adoption; keep as
  recommendation, not finding.

---

## Cross-cutting

- 🔴 **Freshwater reframe breaks the marine figure components.** `clean_data.R` now outputs
  **freshwater only** (5,314,791 records; marine/coastal + unverifiable records removed). So as written, several
  figures will silently empty or mislead:
  * **Fig 1** ecosystem inset — the **Ocean** and **Estuary** bins are now ~0 (those records
    are gone). Rebuild the inset around freshwater classes (river/stream 72.4%, lake 22.6%,
    reservoir 2.1%, canal 1.9%, …).
  * **Fig 2** — the daily "Swimming" site is **Marina del Rey Beach** (marine) → dropped.
    Replace with a freshwater high-frequency recreation site.
  * **Fig 4** — the **Zeebrugge Beach** case study (Belgium coastal, `BWCat = C`) → dropped.
    Replace with an inland spike-and-recovery example; and "Daily E. coli sites" must be
    recomputed on freshwater.
  *Action:* re-pick example sites from the freshwater dataset before these figures are run.

- 🔴 **Use the freshwater N consistently:** the analysis dataset is **5,314,791** records
  (not "9.04 million"). The 9.0 M figure is the all-water cleaned count.

- 🔵 **Data-quality artifacts** exist in source fields (e.g., a `max_date` of `2911-09-15`
  for Bulgaria; US records back to 1898) — screen before any temporal-range figure or claim.
