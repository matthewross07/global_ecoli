# Research Brief

## §1 · Core Claim and Narrative
_Written by: outline-agent, Step 1_

**Core claim:** A harmonized, freshwater-focused global database of fecal
indicator bacteria (5,314,791 observations from ten public sources) reveals that
the public monitoring record fails public health along two measurable axes at
once — an open-data spatial sharing inequality and a temporal sampling rigidity.

**Narrative tension:** Fecal indicator bacteria, especially *E. coli*, are the
primary worldwide tool for judging freshwater safety, yet no global, harmonized
characterization of that record existed. Its absence hid both *where* data are
actually collected and shared and *whether* sampling cadence is fast enough to
protect health.

**Key novelty framing:** Unlike prior single-nation or contents-only
compilations, this work assembles a freshwater FIB record across ten sources and
explicitly measures the collection-versus-sharing distinction and the
sampling-cadence gap, then uses the rare high-frequency sites to show what
actionable monitoring would reveal.

**Outline decisions:**
- Plotting plan: 5 figures (all pre-rendered and supplied in `inputs/figures/`;
  ids matched for PlotOn reuse): `fig_global_distribution_density`,
  `fig_sampling_frequency_mismatch`, `fig_actionability_gap`,
  `fig_high_frequency_case_studies`, `fig_global_safety_summary`.
- Related Work clusters: (1) Global/harmonized water-quality data compilations;
  (2) FIB indicators, thresholds, and health risk; (3) Temporal variability and
  high-frequency monitoring of FIB; (4) Open environmental data and sharing
  barriers.
- Section structure: Abstract, Plain Language Summary, Data and Methods, Results,
  Discussion, Conclusions, Open Research Section (AGU / Earth's Future).

**Potential weaknesses flagged at outline stage:**
- The "high-frequency monitoring reveals transient pollution" framing is only
  partly supported by the case studies: Euclid Beach USA was transient (18.0%
  exceedance) but River Lune UK (83.7%) and Taruheru River NZ (62.5%) were
  chronically polluted. The argument was therefore reframed to "low-frequency
  sampling misrepresents safety in both transient and chronic regimes," which
  the data support.
- High-frequency sites are almost entirely in North America and Europe, so the
  77.6% global safety figure is not a globally representative safety rate and
  must be described as conditional on those sites.
- The claim that China, Russia, and others maintain unshared national networks
  is an interpretive assertion and needs supporting citations or softened
  wording.
- Non-*E. coli* indicator coverage is uneven across sources, and the
  MPN-to-CFU conversion is an approximation; both bound cross-source comparisons.
- All claims are scoped to freshwater FIB observations and to the regions and
  indicators actually represented; no completeness is claimed for unsampled
  regions.

## §2 · Literature Landscape
_Written by: literature-review-agent, Step 3_

**What the literature says about the core claim:** The literature firmly establishes E. coli as the standard freshwater fecal indicator with a strong epidemiological basis linking indicator levels to swimming-associated illness, and it documents that FIB concentrations vary sharply over hours to days, so infrequent grab samples are known to misclassify recreational safety. Large-sample water-quality compilations exist, but they are organized around chemistry or single-nation coverage rather than fecal indicators, and none characterizes the global sharing structure or sampling cadence of FIB — which is exactly the gap this paper fills.

**Strongest prior work (must address in the paper):**
- read2017water (US Water Quality Portal): the closest data-infrastructure precedent and one of our ten sources.
- virro2021grqa / ross2019aquasat / hartmann2014brief: global/continental water-quality compilations that establish the genre but are chemistry-focused.
- whitman2004escherichia / traister2006variability / kim2004public: show infrequent sampling misclassifies safety — the empirical basis for our temporal-rigidity argument.
- searcy2023highfrequency / searcy2021day / heasley2021systematic: high-frequency sampling and nowcasting — the state of the art our findings motivate scaling.
- wilkinson2016fair / sugg2021social / kirschke2020capacity: the FAIR and data-sharing-barrier framing for the collection-vs-sharing-gap interpretation.

**Gaps confirmed by the literature:** (1) no harmonized, global, FIB-focused freshwater dataset; (2) no global characterization of per-site sampling cadence; (3) the distinction between a collection gap and an open-data sharing gap has not been quantified globally.

**Baseline comparisons — verification status:** Not applicable. This is a data-compilation and analysis paper, not a method benchmarked against competitors; no prior work is framed as a baseline to beat. All cited work is contextual, conceptual, or a data precedent.

**Related Work cluster coverage:**
| Cluster | Papers in pool | Notes |
|---|---|---|
| Data compilations | 10 | WQP, AquaSat, GLORICH, GRQA, CAMELS-Chem, salinity, harmonize-wq, microbial-data, exposure-assessment |
| Indicators / thresholds / health | ~9 | Cabelli, Pruss, Wade et al. epidemiology; Edberg; Boehm sea-change; Korajkic |
| Temporal variability / high-frequency | ~10 | diurnal & first-flush variability, nowcasting, high-frequency campaigns |
| Open data / sharing barriers | ~7 | FAIR, social/socio-technical barriers, capacity, info flows |

**Anything the section-writing agent should know:**
- Regulatory references (epa2012recreational, eu2006bathing, who2021recreational) were added to refs.bib but are NOT in the verified pool (Semantic Scholar/OpenAlex do not index them). Cite them in Methods/Discussion, not in Intro/Related Work.
- The actual monitoring data SOURCES (GEMStat, DataStream, Eionet, Hub'Eau, NMMP, LAWA, WPdx, ANA) still need data citations in the Methods and Open Research sections; only WQP-adjacent tooling is in the pool.
- "Related Work" follows the CS convention; for Earth's Future this may read better merged into the Introduction or retitled "Background."
