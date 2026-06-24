# Outline Review Flags

Concise list of claims in `paper_outline.Rmd` that read **too authoritatively**, may be
**inaccurate**, or rest on **uneven data coverage** — with suggested defensive rewording.
Scope: the *existing* sections (Exec Summary, Figs 1–4, Discussion). The new **Methods**
section already incorporates these caveats. Severity: 🔴 fix before submission · 🟡 soften/verify · 🔵 minor/citation.

Ground-truth references: `country_summary.csv`, `states_summary.csv`, indicator×source
counts from `harmonized.feather`, and `methods_digest.md`.

---

## §1 Executive Summary & Core Thesis

- 🔴 **"43.7% from Europe and Canada"** — does not reconcile with the data. From
  `country_summary.csv`, US ≈ 54.4% (✓ matches "54.3%"), but Europe + Canada sums to
  **≈38.7%**, not 43.7%. The "54.3% + 43.7% = 98%" framing implies only ~2% for the rest
  of the world, yet **Mexico (268k), South Africa (167k), India (106k), New Zealand (67k),
  Uruguay, Haiti** etc. are present (~7% RoW). *Fix:* recompute the regional shares; avoid
  phrasing that erases the Global-South records we do have.

- 🟡 **"our primary tool for protecting public health"** / **"FIB datasets"** framed as a
  comprehensive whole — but our compilation is **E. coli–anchored** and unevenly captures
  other indicators (e.g., **enterococci absent from WQP and Hub'Eau**). *Soften:* "the
  most widely reported indicators of fecal contamination," and acknowledge indicator scope.

- 🟡 **"less than 6.1% of monitoring sites globally achieve daily or near-daily sampling"**
  — Figure 3 computes this over **multi-sample sites (n ≥ 2)**, not "sites globally."
  Single-observation sites are excluded from that denominator. *Fix:* align the denominator
  wording ("of sites with ≥2 samples") between Exec Summary and Fig 3.

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

- 🔵 **11.8% ≥100 obs / 1.0% ≥500 obs** — verify against the cleaned dataset (numbers
  currently asserted in prose without a shown computation).

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

- 🔴 **Indicator-coverage caveat is the most important omission.** Any statement framed as
  "global FIB monitoring" should acknowledge the **E. coli-anchored, source-dependent**
  indicator capture (esp. missing enterococci in WQP & Hub'Eau). Now stated in Methods §M.2;
  ensure Exec Summary and figure captions don't contradict it.

- 🟡 **"9.04 million clean records"** vs **9,055,019 harmonized** — reconcile the exact
  post-cleaning N and use it consistently.

- 🔵 **Data-quality artifacts** exist in source fields (e.g., a `max_date` of `2911-09-15`
  for Bulgaria; US records back to 1898) — screen before any temporal-range figure or claim.
