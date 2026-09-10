---
layout: default
title: DataDictionaries
parent: DataDescriptionStandard
nav_order: 2
---

# DataDictionaries

## Definition

Data dictionaries describe the information needed to decode and model
each data file. That means: data types; encoding of any categorical or
missingness codes; valid and invalid value lists; and any provenance
required for understanding (e.g., that a set of response times has been
log-transformed).

### Example entry

| Survey LongName | Question ID | Question Text | Question Type Display Name | Result Type | Missingness Codes | Response Range | Response Text |
|---|---|---|---|---|---|---|---|
| Evening EMA | na_upset | How upset have you felt today? | Slider | numeric | -999 | 0–100 | Not at all, Extremely |

## How data dictionaries differ from codebooks

Data dictionaries tend to be designed for technological use, and are
often stored as a single table in a database or a single spreadsheet
file. They help detail the structure of the respective data files. Data
management teams use data dictionaries to transform raw data files into
usable databases, in order to reproduce analyses or verify descriptive
statistics; they may also serve as a quick-reference guide when working
directly from a data file. Conversely, a well-maintained and documented
database should contain enough information to be reconstructed back into
raw data and its data dictionary.

Data dictionaries may be associated with **any** data file, including raw
or intermediate files — unlike codebooks, which are typically paired with
preprocessed, analysis-ready data. See [Codebooks](Codebooks) for the
counterpart definition.

## What a data dictionary should include

- Data type for each variable
- Encoding of categorical and missingness codes (see
  [DescribingMissingness](DescribingMissingness))
- Valid and invalid value lists / response ranges
- Provenance notes for any transformed variable
- A structured, machine-ingestible format — CSV or TSV are preferred for
  the table itself

## Generating data dictionaries with WearITReadR

WearITReadR can generate data dictionaries automatically from study data
pulled via the Wear-IT API, or from translated Qualtrics studies. See
[WearITReadR](../WearITReadR) for details, and the
[AI-generated study data dictionary example](https://github.com/ymirssbm/wearitreadr/blob/main/Examples/AI%20Generated%20Study%20Example/DataDictionary.csv)
for a worked example.
