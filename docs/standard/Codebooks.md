---
layout: default
title: Codebooks
parent: DataDescriptionStandard
nav_order: 1
---

# Codebooks

## Definition

Codebooks define the conceptual characteristics of the measurements, their
relationships to other constructs, and their provenance — written in a
human-friendly way. This should include justification for design
decisions related to the meaning or operationalization of constructs.

For example:

> We selected Happy, Joyful, and Cheery as the indicators for positive
> affect. These represent a subset of the PANAS positive affect scale
> (Watson, Clark, & Tellegen, 1988), and were selected because of their
> high loadings in prior work. The overall PA score is derived as a mean
> of these three indicators, omitting missing values (code link).

## How codebooks differ from data dictionaries

Codebooks are most commonly used in conjunction with data files or
databases that have already been preprocessed (e.g., outliers removed,
data-entry errors fixed) and are ready for analysis. For this reason,
codebooks tend to be the primary documentation researchers reach for —
while data dictionaries are used more by data management teams working
with raw files.

One way to think about the difference: codebooks are built to be
**human-accessible**, whereas data dictionaries are primarily
**machine-readable**. The information in the two overlaps significantly —
for example, both typically describe the mapping between the qualitative
answers a participant selected and the numeric values that represent them
in the data — but they serve different audiences and different points in
the data pipeline.

See [DataDictionaries](DataDictionaries) for the counterpart definition.

## What a codebook should include

Following the design principles in the
[DataDescriptionStandard](index) overview, a codebook should:

- Be written in a simple, human-readable markup format (HTML or Markdown
  are preferred)
- Include the conceptual meaning of each measured construct, not just its
  numeric encoding
- Provide full provenance for any item or scale used, including any
  modification from its original/canonical form
- Include rich paradata: how, how often, and under what conditions each
  item was delivered
- Include rich metadata: statistical description of the data to aid
  interpretation
- Include missingness codes and, where appropriate, missingness
  description — see [DescribingMissingness](DescribingMissingness)
- Include screenshots or short video clips of the delivered UI for
  interactive or configurable items — see
  [UIAndDelivery](UIAndDelivery)

## Generating codebooks with WearITReadR

WearITReadR's codebook generator retrieves study data directly from the
software that delivered the study, and can embed UI screenshots (via the
screenshot scraper) directly into the generated output. See
[WearITReadR](../WearITReadR) for details, and the
[RCC Project codebook example](https://ymirssbm.github.io/wearitreadr/Examples/Recovery%20Community%20Center%20(RCC)%20Project/Codebook.html)
for a worked example generated from a real study.
