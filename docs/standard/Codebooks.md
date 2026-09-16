---
layout: default
title: Codebooks
parent: Data Description Standard
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
**machine-readable**. 

Note that the information in data dictionaries and codebooks overlaps significantly. For example, both include some description of the mapping between the qualitative answers selected by participants and the numeric values that represent them in the data.    

See [DataDictionaries](DataDictionaries) for the counterpart definition.

## What a codebook should include

Following the design principles in the
[Data Description Standard](index) overview, a codebook should include:

### Title page

- Name of study
- Authors
- Any desired graphics
- Funding source(s)

### Abstract page

- Brief description of study
- Study aims
- History, and date of data collection
- Location of data collection
- People involved and respective roles of those people
  - Who, what, where, when, + what did you do

### Executive summary (optional)

- A results page summarizing main findings of the study

### Table of contents

### Variable page for each question

**Text/name elements**

- Variable name
  - As it appears in the dataset
- Human readable name
- If it's a survey question
  - Exactly as it is presented to participant
- If observational, or obtained from passive technology
  - Description of variable in layman's terms
  - If layman's terms not possible, citation of a longer explanation of terms

**Paradata / metadata elements**

- Privacy status (e.g., is this identifying info?)
- Modeling characteristics (e.g., reaction time data should be log transformed)
- Transformations applied to the raw data
- Skip logic
  - For whom and when this data is collected
  - Trigger / JIT-delivery logic
  - Adaptive design logic
- How the data was obtained
  - Sensing, survey, observation, circling something on a page, digital slider, etc.
- Type of data
  - Numeric, categorical, continuous, etc.
- Possible values of the data, including item codes (1 = strongly disagree)
  - I.e., ranges from 0–10, 1–5 ranging from strongly disagree to strongly agree
- Screenshot of question
- Measurement citation
- Distance between measurements
  - e.g., 1 day, 1 hour (if complex, this will need to be described in the skip logic)

**Statistical elements**

- Descriptives of variable
  - Min, max, mean, std dev, # of valid observations
- Report missingness
  - Frequency of missingness
  - Structure of missingness
    - MAR, MNAR, MCAR
  - For repeated assessment data
    - ICC, min, max, means, standard deviation, and missingness (planned and unplanned range)
  - Types of missingness
    - Refused, don't know, not applicable, not ascertained
  - Code for types of missingness in data
    - 99999, -1, -5, -7, NA, etc.
  - For questions using uneven assessment intervals
    - Descriptions of the min, max, means, and standard deviation of the distance between measurements


## Generating codebooks with WearITReadR

WearITReadR's codebook generator retrieves study data directly from the
software that delivered the study, and can embed UI screenshots (via the
screenshot scraper) directly into the generated output. See
[WearITReadR](../WearITReadR) for details, and the
[RCC Project codebook example](https://ymirssbm.github.io/wearitreadr/Examples/Recovery%20Community%20Center%20(RCC)%20Project/Codebook.html)
for a worked example generated from a real study.
