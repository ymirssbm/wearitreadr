---
layout: default
title: Data Description Standard
nav_order: 4
has_children: true
---

# DataDescriptionStandard
{: .no_toc }

## Table of contents
{: .text-delta }

1. TOC
{:toc}

---

## Why a new standard

Adequate data description standards are increasingly important for the
usability of shared datasets, and for the reproducibility and
replicability of scientific findings. One of the main challenges in
reusing shared data — or attempting to replicate or reproduce past
results — is that researchers not privy to the original data collection
procedure may struggle to interpret the unique context in which the data
was collected.

It was once safe to assume that a paper reporting use of the PANAS meant
participants completed the whole scale on paper. With the profusion of
modern implementations on computers, smartphones, watches, and other
interactive modalities, that assumption no longer holds. Researchers today
might deliver only a subset of items, use a different modality of
assessment (e.g., a continuous slider instead of a discrete Likert scale),
or adapt delivery to the participant in real time.

We argue that much of the burden of maintaining good documentation
standards can be taken on by the same technologies — EMA software, cloud
computing, adaptive algorithms — that create the complexity in the first
place. This section lays out formal definitions of the recommended
documentation types, and specific reporting recommendations for the areas
where complex, adaptive designs make description hardest.

## The three documentation types

- **[Codebooks](Codebooks)** — human-oriented documents defining the
  conceptual characteristics of measurements, their relationships to
  other constructs, and their provenance and design justification.
- **[Data Dictionaries](DataDictionaries)** — machine/technical-oriented
  documents describing the information needed to decode and model each
  data file: data types, codes, valid value ranges, and provenance.
- **[Data Manuals](DataManuals)** — the umbrella document tying together
  every codebook and data dictionary for a study, along with survey
  timing, intervention triggering, data use agreements, regulatory
  information, and preregistration/IRB details.

## Guiding design principles

Some design elements are common to both codebooks and data dictionaries.
Both should be:

- **Human readable** — written in a simple, commonly used markup format
  (e.g., HTML or Markdown) rather than a compressed or binary format
  requiring specialized software. A good rule of thumb: it should be
  possible, even if time-consuming, to reconstruct the important
  information from a printout.
- **Machine readable** — stored in a structured, documented, easily
  ingested format. CSV/TSV for data dictionaries, and structured
  JSON, XML, HTML, or Markdown for codebooks, satisfy both requirements
  at once.
- **FAIR** — Findable, Accessible, Interoperable, and Reusable
  (Wilkinson et al., 2016). Findable means searchable tag data in a
  sensible form. Accessible means readable by both machines and humans
  without custom software (in practice, codebooks tend to be more
  human-accessible; data dictionaries more machine-oriented).
  Interoperable means built to a clear, established standard. Reusable
  means separating general from specific — any item or scale used should
  include its complete provenance (e.g., "this item is from the PANAS,
  and was transformed in these ways").
- **Rich in paradata** — describing the process and means of data
  collection in its entirety (e.g., how often an item is delivered, and
  under what conditions).
- **Rich in metadata** — including the statistical elements of the data
  needed to aid interpretation.

## Where documentation gets hardest

Complex, adaptive designs (EMA, ambulatory assessment, JITAIs, planned
missing designs, passive sensing) make several parts of the standard
documentation process much harder than in traditional single- or
few-assessment studies. This standard gives specific guidance for three
of the hardest areas:

- **[Describing Missingness](DescribingMissingness)** — adaptive skip and
  trigger logic creates missingness patterns that simple frequency
  reporting can't capture.
- **[Software And Hardware](SoftwareAndHardware)** — passive sensing
  hardware and cloud processing pipelines make undocumented decisions
  that can affect results and break replication.
- **[UI And Delivery](UIAndDelivery)** — the device, format, and scale used
  to deliver an assessment can bias responses in ways that are rarely
  documented.

Finally, **[JSON Schema](JSONSchema)** documents the machine-readable
specification (`study.json`) that WearITReadR uses to implement this
standard in practice.
