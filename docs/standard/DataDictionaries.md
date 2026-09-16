---
layout: default
title: Data Dictionaries
parent: Data Description Standard
nav_order: 2
---

# DataDictionaries

## Definition

Data dictionaries describe the information needed to decode and model each data file. That means data types, encoding of any categorical or missingness codes, valid and invalid value lists, and any provenance required for understanding (e.g. that these response times are log-transformed).  

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

Data dictionaries tend to be designed for technological use, and the dictionary for a data file is often stored as a single table in a database or a single spreadsheet file. Data dictionaries help to detail the structure of the respective data files (Buchanan et al., n.d.). Data management teams use data dictionaries to transform raw data files into usable databases in order to reproduce analyses or verify descriptive statistics; they may also serve researchers as quick-reference guides when working from a data file. Conversely, a well maintained and documented database will contain enough information to be transformed back into raw data and data dictionary files.  


## What a data dictionary should include

Following the design principles in the
[Data Description Standard](index) overview, a data dictionary should
include one row per item/variable, with the following fields:

- **Survey Name**
  - The survey or instrument the item belongs to
- **Item ID**
  - The variable name as it appears in the dataset
- **Question ID**
  - The unique identifier for the question within the survey
- **Question Text**
  - The question exactly as presented to the participant
- **Question Type Display Name**
  - The response format used to collect the data (e.g., Slider, Multiple Choice, Text Entry)
- **Result Type**
  - The data type of the stored value (e.g., numeric, categorical, string)
- **Missingness Codes**
  - The value(s) used to represent missing data (e.g., -999, NA)
- **Response Range**
  - The valid range or set of values the item can take (e.g., 0–100, 1–5)
- **Response Text**
  - The labels corresponding to the response options or endpoints of the range (e.g., "Not at all" to "Extremely")
  

## Generating data dictionaries with WearITReadR

WearITReadR can generate data dictionaries automatically from study data
pulled via the Wear-IT API, or from translated Qualtrics studies. See
[WearITReadR](../WearITReadR) for details, and the
[AI-generated study data dictionary example](https://github.com/ymirssbm/wearitreadr/blob/main/Examples/AI%20Generated%20Study%20Example/DataDictionary.csv)
for a worked example.
