# Submission Guidelines — *Earth's Future* (AGU / Wiley)

Target journal: **Earth's Future**, an open-access AGU journal for
broad-audience, solutions-oriented research on the human–Earth system. Use the
provided `template.tex` (document class `agujournal2019`, with
`agujournal2019.cls` and `trackchanges.sty` alongside it).

> Items marked *(verify)* are standard AGU norms that should be confirmed
> against the current Earth's Future author guidelines before final submission.

## Document class and front matter

- `\documentclass{agujournal2019}` with `\journalname{Earth's Future}` (already set).
- Required front-matter commands: `\title{}`, `\authors{}`, `\affiliation{}{}`,
  `\correspondingauthor{}{}`.
- **Key Points:** provide **1 to 3** key points in the `keypoints` environment.
  Each MUST be **≤ 140 characters**, a self-standing statement with **no special
  characters and no acronyms**. They summarize the main conclusions.
- **Abstract:** one paragraph, **≤ 250 words** (AGU standard for all journals
  except GRL). Open with the problem, briefly describe the new data/analyses,
  then state the main conclusions, how they are supported, and key uncertainties.
- **Plain Language Summary:** **optional** for Earth's Future but strongly
  encouraged. A single paragraph **≤ 200 words** conveying the same content as
  the abstract in completely jargon-free language for journalists, educators,
  and scientists outside the field.

## Body structure

- Standard outline: **Introduction → Data and Methods → Results → Discussion →
  Conclusions**. Choose descriptive section titles where helpful (e.g. a "Data"
  section may carry a descriptive heading).
- Headings are sentence-style fragments, first letter capitalized, not starting
  with a number or lowercase letter.
- **Balanced numbering:** no Section 1 without a Section 2; no 2.3.1 without a
  2.3.2.
- **Do NOT use bulleted lists.** Enumerated (numbered) lists are acceptable.
- Place figures and tables near their first mention.

## Mandatory back-matter sections (after Conclusions)

1. **Open Research Section** — *required.* A statement of where the data
   supporting the conclusions can be obtained. Data may **not** be listed as
   "available from the authors" or stored solely in supporting information.
   Archived datasets and software must be cited in the reference list with
   persistent identifiers (e.g. a repository DOI).
2. **Inclusion in Global Research Statement** — *as applicable.* Encouraged when
   research spans regions/countries/communities; disclose permits, local
   collaboration, and end-users. Relevant here because the dataset aggregates
   national monitoring data from many countries.
3. **Conflict of Interest disclosure** — required; state explicitly even if none.
4. **Acknowledgments** — funding, contributions, secondary affiliations.

## Figures and tables

- Figure captions go **below** the figure; table titles go **above** the table.
- Include figures with `\includegraphics[width=\textwidth]{...}`.
- Do **not** use `\subfigure` or `\psfrag`.
- Five pre-rendered figures are provided in `inputs/figures/` and should be used
  as-is (PlotOn mode): `fig_global_distribution_density`,
  `fig_sampling_frequency_mismatch`, `fig_actionability_gap`,
  `fig_high_frequency_case_studies`, `fig_global_safety_summary`.

## References and citations (strict)

- AGU uses **APA-style** references via `apacite`.
- Use **only** `\cite{}` for parenthetical citations and `\citeA{}` for in-text
  citations. **Do NOT use** `\citep`, `\citet`, `\citeyear`, `\citealp`,
  `\nocite`, or other citation commands — they are unsupported by the class.
- Cite archived data and software in the reference list (per Open Research).

## Length and tone

- Earth's Future does not impose a rigid page limit but expects **concise**
  writing *(verify current limits)*. Target a focused research article rather
  than an exhaustive report.
- Audience is interdisciplinary; define terms and keep the framing accessible,
  consistent with the Plain Language Summary.
