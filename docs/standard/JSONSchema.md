---
layout: default
title: JSON Schema
parent: Data Description Standard
nav_order: 7
---

# JSONSchema
{: .no_toc }

## Table of contents
{: .text-delta }

1. TOC
{:toc}

---

## Overview

Accompanying the WearITReadR app is a JSON specification that acts as an
initial draft of a machine-readable data description standard for complex
study designs. The schema lives in the repo at
[`inst/schema/0.1.0/study.json`](https://github.com/ymirssbm/wearitreadr).

This schema is what makes the rest of the standard *implementable*: rather
than every research team inventing its own study description format,
WearITReadR (and any tool built to interface with it) can generate,
validate, and consume a single, structured `study.json` file.

## Why JSON

- **Validators exist.** JSON's ecosystem of validators lets us — and
  generative AI tools — formally check whether an ingested JSON file
  follows the required specification. If it doesn't, an informative error
  is thrown, rather than a translator silently producing malformed or
  incomplete output.
- **Translators are easy to build and test against it.** Because
  conformance can be checked programmatically, an AI assistant can
  iteratively test whether, where, and how a translator is failing against
  the schema, and correct it — this is how the
  [Qualtrics translator](../WearITReadR#using-wearitreadr-with-other-data-collection-apps)
  was built in a matter of minutes.
- **It's both human- and machine-inspectable**, satisfying the
  readability principles laid out in the
  [DataDescriptionStandard overview](index).

## What the schema captures

The `study.json` specification is designed to capture the full set of
metadata and paradata categories described throughout this standard,
including (see [DataManuals](DataManuals) for the complete list):

- Missingness codes and structure
- Skip and trigger ("JIT") logic
- Preprocessing steps and provenance chains
- Software/hardware name, version, and container links
- Measure source and variation information
- Study design and survey timing
- UI/display information
- Adaptive design logic

## Versioning

The schema is versioned (currently `0.1.0`), reflecting that this is an
early, evolving draft. As a collaborative standard, we intend to engage
other researchers in open discussion of the schema and the standard more
broadly — see [Contributing](../Contributing).

## Using the schema

- **Validating a study JSON** — run it through a standard JSON Schema
  validator against `inst/schema/0.1.0/study.json` to confirm conformance
  before generating a codebook, data dictionary, or data manual from it.
- **Building a new translator** — see the
  [AI Generated Study Example](https://github.com/ymirssbm/wearitreadr/tree/main/Examples)
  in the repo, and the
  [WearITReadR](../WearITReadR) page for how the Qualtrics translator was
  built as a reference implementation.
