---
layout: default
title: SoftwareAndHardware
parent: DataDescriptionStandard
nav_order: 5
---

# SoftwareAndHardware
{: .no_toc }

## Table of contents
{: .text-delta }

1. TOC
{:toc}

---

## Why hardware and software need to be documented

Researchers often rely on both passive sensing hardware — heart rate
monitors, smart device sensors, eye trackers, GPS trackers, actigraphy —
and data processing software to collect and manage data. These devices
make it possible to passively sense and dynamically track participants
over time. The resulting data can trigger dynamic assessments or
interventions, be incorporated into skip logic, drive predictive models of
participant behavior, or supplement traditional survey data.

Hardware differs greatly by make and model and lacks standardization.
Such hardware also produces complex data that requires processing —
whether on-device, in a vendor's cloud platform, or via specialized
researcher-side software. For many proprietary devices, on-device and
cloud-based processing code can be altered or updated by the vendor
without warning, further complicating reproducibility.

### Small decisions, large consequences

Passive sensing hardware and processing software make many decisions the
researcher never sees, and any of them can affect the data and results.
For example: passive sensing technology often relies on data-upload
chunking combined with load-balancing, to upload data to a server in
parallel for speed and reliability under high traffic. This process can
result in lost chunks. Two studies using the same devices, but with
different chunking/load-balancing settings, could end up with two
different patterns of missingness — jeopardizing replication, even though
nothing about the study design itself changed.

Beyond passive sensing, researchers may use software for cognitive
testing, LLM-assisted qualitative analysis, or LLM-generated survey
questions. Even within the same statistical software package, version
differences can cause failures to replicate. There's also currently no
clear standard for describing the functionality of a deep learning or
generative AI tool in depth — serialization can help for some model types,
but these cases are varied enough that general guidelines, rather than
precise rules, are often the most that's possible. This becomes harder
still with closed, proprietary software.

## What to include

- **Name and version** of every piece of hardware and software used
- **How and when** each was used in the data collection or processing
  pipeline
- As much detail as possible about **cloud tools and on-device
  processing** steps, not just the top-level software name
- Preference for tools with a **script interface**, or point-and-click
  tools that produce a recordable, machine-replicable transcript of the
  processing steps taken
- **Containerization** of the software environment where feasible — an
  excellent (if technically demanding) way to preserve and document
  version history. See Peikert & Brandmaier (2019) and The Turing Way
  Community (2022) for implementation guidance.
- **Serialization and documentation** of any model used, where possible
- A preference for **open-source hardware and software**, since it allows
  full transparency of the underlying structure and functionality of the
  design

## Related

See [DescribingMissingness](DescribingMissingness) for how
hardware/software processing decisions (like chunking) can directly shape
missingness patterns, and [JSONSchema](JSONSchema) for how WearITReadR
captures software/version metadata in its study specification.
