---
layout: default
title: WearITReadR
nav_order: 3
---

# WearITReadR
{: .no_toc }

Software documentation for the WearITReadR Shiny app and R package.
{: .fs-6 .fw-300 }

## Table of contents
{: .text-delta }

1. TOC
{:toc}

---

## What is WearITReadR

The WearITReadR repo contains a Shiny app and open-source R package,
currently in development. Functionality includes:

- A **Wear-IT API pull** (Wear-IT is a smartphone EMA data collection app)
- A customizable **codebook**, **data dictionary**, and **study flowchart**
  generator
- An **AI study generator and modifier**, which generates JSON following
  WearITReadR's data description and storage spec
- A **screenshot scraper**, which walks a study block map to generate YAML
  that walks a study and scrapes screenshots (which can then be embedded
  inside a generated codebook)
- A **Qualtrics translator**, which translates from the Qualtrics API into
  our internal JSON storage format, then parses it — allowing all of the
  above to be generated from Qualtrics surveys

See the `examples` folder in the
[WearITReadR repo](https://github.com/ymirssbm/wearitreadr) for more.

Accompanying the app is a JSON specification that acts as an initial draft
of a data description standard for complex study designs — see
[`inst/schema/0.1.0/study.json`](https://github.com/ymirssbm/wearitreadr)
in the repo, and [JSONSchema](../standard/JSONSchema) on this site for a
walkthrough.

## Running WearITReadR in R

```r
devtools::install_github("ymirssbm/wearitreadr")
library(wearitreadr)
run_app()
```

See [GettingStarted](GettingStarted) for full installation details.

## The Shiny App

The Shiny app is the primary interface for WearITReadR. It connects to a
study's Wear-IT API and lets you generate:

- Codebooks, filtered and customized by topic or subset
- Data dictionaries, one per data file
- Study flowcharts describing the flow of participants and assessments
  through the study design

## Using WearITReadR with other data collection apps

Although WearITReadR is designed primarily to interface with the Wear-IT
API, it can be adapted to work with other data collection APIs as well.

As a proof of concept, we built a simple translator that converts studies
run on Qualtrics into WearITReadR's format via an API translator function.
This lets any of WearITReadR's functionality be used on data collected
through Qualtrics. This translator was intentionally "vibe coded" —
written quickly with the help of a generative AI assistant — to
demonstrate that even researchers with limited technical background could
build an API translator from their preferred data collection tool to the
WearITReadR spec. The full process took only a couple of minutes.

Similar translators could, in principle, be built for any data collection
API or software. Because WearITReadR is built around a JSON specification,
it's relatively easy to build and test new translators: JSON validators let
both humans and generative AI formally check whether an ingested JSON
follows the required specification. If it doesn't, an informative error is
thrown. This makes the process of building translators with AI assistance
increasingly seamless, since the model can test whether, where, and how a
translator is failing, and correct it.

**Note:** The study screenshot scraper and Qualtrics translator have not
yet been implemented into the Shiny app. Both currently exist as standalone
R functions. The screenshot scraper additionally requires
[Maestro Studio](https://maestro.dev/).

## AI Study Generator

The AI study generator and modifier produces JSON following WearITReadR's
data description and storage specification. This allows a study design to
be drafted, or an existing study JSON to be modified, using natural
language instructions rather than hand-editing JSON directly. Generated
JSON can be validated against the
[JSON schema](../standard/JSONSchema) to confirm it conforms to spec
before use.

## Screenshot Scraper

The screenshot scraper walks a study's block map and generates YAML
instructions to navigate the study, capturing a screenshot at each step.
These screenshots can then be embedded directly inside a generated
codebook, giving readers an exact visual record of the UI a participant
saw — useful given how much small interface decisions (layout, slider
behavior, labeling) can affect responses. See
[UIAndDelivery](../standard/UIAndDelivery) for why this matters.

The screenshot scraper requires [Maestro Studio](https://maestro.dev/) and
is not yet integrated into the Shiny app.

## Examples

- **Codebook**, generated from a real study —
  [Recovery Community Center (RCC) Project](https://ymirssbm.github.io/wearitreadr/Examples/Recovery%20Community%20Center%20(RCC)%20Project/Codebook.html)
- **Study flowchart** for the RCC Project (see the Examples folder in the
  repo)
- **Data dictionary**, generated for an AI-generated example study —
  [DataDictionary.csv](https://github.com/ymirssbm/wearitreadr/blob/main/Examples/AI%20Generated%20Study%20Example/DataDictionary.csv)

See the `Examples` folder in the repo for additional examples of AI study
generation, the Qualtrics translator, and more.
