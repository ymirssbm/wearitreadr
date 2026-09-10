---
layout: default
title: GettingStarted
nav_order: 2
---

# GettingStarted
{: .no_toc }

## Table of contents
{: .text-delta }

1. TOC
{:toc}

---

## What WearITReadR does

WearITReadR pulls study data directly from the Wear-IT API — the software
that actually delivered the study — and uses it to generate:

- Customizable **codebooks**
- **Data dictionaries**
- **Study flowcharts**
- JSON-based study specifications, editable through an AI study
  generator/modifier
- Screenshots of survey items, scraped by walking a study's block map
- Translated studies from other platforms (currently Qualtrics) into
  WearITReadR's internal JSON format, so the same generators can be used
  on non-Wear-IT data

## Requirements

- R (recent version recommended)
- Access to the WearITReadR package source:
  [github.com/ymirssbm/wearitreadr](https://github.com/ymirssbm/wearitreadr)

## Installation

```r
# install.packages("devtools") # if not already installed
devtools::install_github("ymirssbm/wearitreadr")
```

## Running the app

```r
library(wearitreadr)
run_app() # launches the Shiny interface
```

From the Shiny app you can connect to a study's Wear-IT API credentials and
generate a codebook, data dictionary, or study flowchart directly.

## Where to go next

- See **[WearITReadR](WearITReadR)** for a full walkthrough of each feature
  (API translators, AI study generator, screenshot scraper) and worked
  examples.
- See **[DataDescriptionStandard](standard/)** if you want to understand
  *what* WearITReadR is generating and why — the definitions and
  reporting recommendations behind codebooks, data dictionaries, and data
  manuals.

## Status

WearITReadR is under active development. The Shiny app currently supports
codebook, data dictionary, and flowchart generation from the Wear-IT API.
The study screenshot scraper and Qualtrics translator are implemented as
standalone R functions and have not yet been integrated into the Shiny
app interface. The screenshot scraper additionally requires
[Maestro Studio](https://maestro.dev/).
