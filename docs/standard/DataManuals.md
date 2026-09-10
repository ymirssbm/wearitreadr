---
layout: default
title: DataManuals
parent: DataDescriptionStandard
nav_order: 3
---

# DataManuals

## Definition

It's common for researchers and data management teams to have multiple
data files, each associated with its own codebook and data dictionary,
under a single study. To describe the complete set, we introduce the term
**Data Manual**.

A Data Manual includes:

- The [codebook](Codebooks) for each substantive topic
- The [data dictionary](DataDictionaries) for each data file
- Study meta- and paradata
- Descriptions of survey timing
- Intervention/trigger ("JIT") delivery logic
- Data use agreements
- Regulatory information
- Preregistration and IRB information

In the same way that a researcher should be able to take a relatively
unstructured data file and its corresponding data dictionary and
reconstruct a meaningful database, a **complete data manual should allow
anyone to fully replicate every aspect of a study.**

## Why a manual, and not just files

Codebooks and data dictionaries each document a slice of a study — a
construct, or a single data file. Neither is designed to capture the
overall study design: how participants moved through the study, what
triggered an assessment, what ethical and regulatory context the data was
collected under. The Data Manual is the container that ties all of these
pieces together at the study level, so that a reader doesn't have to
reconstruct the full picture from scattered documents.

## Proposed standard: required content

We propose that codebooks, data dictionaries, and data manuals — taken
together — must include standardized methods of recording metadata and
paradata of the following types:

**Metadata**
- Missingness (see [DescribingMissingness](DescribingMissingness))
- Skip logic
- Preprocessing steps / provenance chain
- Software, version, and link to container and code (see
  [SoftwareAndHardware](SoftwareAndHardware))
- Measure source and variation information

**Paradata**
- Study design
- Survey timing
- Trigger / JIT-delivery logic
- UI/display information (see [UIAndDelivery](UIAndDelivery))
- CONSORT: recruitment / eligibility / selection processes
- Adaptive design logic
- ML learners, including serialized model output (parameters, structure),
  versions, and containers

## Generating data manuals with WearITReadR

WearITReadR's generator is designed to produce codebooks, data
dictionaries, and — eventually — full data manuals for different subsets
of a study's data, pulled directly from the software that delivered the
study. See [WearITReadR](../WearITReadR) for current functionality.
