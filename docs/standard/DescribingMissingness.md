---
layout: default
title: DescribingMissingness
parent: DataDescriptionStandard
nav_order: 4
---

# DescribingMissingness
{: .no_toc }

## Table of contents
{: .text-delta }

1. TOC
{:toc}

---

## Why missingness is hard to describe in complex designs

Researchers commonly emphasize the importance of describing missingness.
Patterns of missingness that are not random, as well as frequent
missingness generally, can bias statistical results and threaten
generalizability. Currently proposed standards for reporting missing data
mostly emphasize reporting the structure and frequency/percentage of
missingness per variable — which is sufficient for traditional designs
with one or a few equally-spaced assessments, but breaks down for complex,
adaptive designs.

### A worked example

Consider a study assessing substance use craving in 100 participants.

- **Single time point:** 30 missing assessments gives a complete picture —
  30 people didn't respond.
- **10-day daily diary:** those same 30 missing assessments might now
  represent 30 people each missing one day, 3 people missing all ten days,
  or anything in between. The raw count alone no longer tells you what
  happened.
- **GPS-triggered EMA** (e.g., prompting near a bar or liquor store, capped
  at 10 prompts/month): missingness could now mean a participant never
  triggered a prompt, triggered one but ignored/silenced it, or would have
  triggered one but had already hit the prompt limit — three substantively
  different things, indistinguishable from a simple missing-data count.
- **Adaptive limits** (e.g., a prompt limit set by a fitted time-varying
  stress model): all of the above reasons still apply, plus the model and
  its inputs may themselves be difficult to describe in reproducible
  detail.

This creates two core problems:

1. Adaptive designs use skip/trigger logic, sometimes based on complex,
   nonlinear decision trees. Without rich paradata describing that logic,
   researchers outside the original study can't interpret the data's
   missingness context.
2. Even with the exact skip/trigger logic in hand, that alone may not
   explain *how often* an assessment was actually delivered, or *to whom*.
   Missingness due to participant non-engagement, skip logic, and
   assessments that simply never triggered all carry different
   substantive meanings — which means rich descriptive statistics of
   missingness are needed in addition to the logic itself.

## What to include

For repeated-assessment data:

- **Minimum, maximum, standard deviation, and mean** values for each
  variable, both overall and averaged across participants
- **Intraclass correlations for missingness**, to describe the balance of
  between- vs. within-subject variability in missingness
- **Number of assessments completed** and **number delivered**, alongside
  the **maximum possible** number of assessments, for each item
- **Missingness codes** distinguishing different kinds of missingness —
  for example:
  - `-1` = skipped by participant
  - `-3` = skip logic triggered
  - `-999` = survey not completed

  Missingness codes should appear in **both** the codebook and the data
  dictionary (see [Codebooks](Codebooks) and
  [DataDictionaries](DataDictionaries)).
- Where useful, **missingness plots or missingness analysis** included
  directly in the codebook.

## Describing complex design more broadly

Well-established standards exist for describing classical research
protocols, and should still be followed alongside the above wherever
applicable:

- **Randomized controlled trials** — [CONSORT](http://www.consort-statement.org/) guidelines
- **Observational studies** — [TREND](https://www.cdc.gov/trendstatement/) or [STROBE](https://www.strobe-statement.org/) guidelines
- **Qualitative studies** — [COREQ](https://academic.oup.com/intqhc/article/19/6/349/1791966) or [SRQR](https://journals.lww.com/academicmedicine/fulltext/2014/09000/standards_for_reporting_qualitative_research__a.21.aspx)
- For other designs, see the [EQUATOR Network](https://www.equator-network.org/)
