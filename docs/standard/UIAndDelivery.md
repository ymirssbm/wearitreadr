---
layout: default
title: UI And Delivery
parent: Data Description Standard
nav_order: 6
---

# UIAndDelivery
{: .no_toc }

## Table of contents
{: .text-delta }

1. TOC
{:toc}

---

## Why UI and delivery details matter

The widespread availability of smart devices has substantially improved
real-time survey assessment in many ways. Smart devices help ensure that participants don't
fabricate or tamper with data, are compact, and include sensor
technologies (cameras, microphones, accelerometers). On-device computation
also allows real-time adaptation and automated prompt timing, so that data can be
collected and intervention delivered using precise timing.

But smart-device data collection relies on research software that lacks
standardized interfaces. Researchers today have an enormous amount of flexibility in how they
choose to deliver an assessment. For example, the same scale (say, the
PANAS) might be delivered as:

- A series of visual-analog sliders on a scrolling smartphone display
- A button list shown one question at a time on a smartwatch
- A discrete label list with clickable elements on a PC display
- A spoken list via text-to-speech through a home assistant

On top of these high-level choices, there's an enormous number of smaller
UI decisions to be made. The same scale delivered by two different data collection apps may vary by layout, size, anchoring, and interactivity. These details are rarely described and may bias the resulting distributions or results in unintuitive ways. 

### What we know changes outcomes

- Devices with small screens can be a problem for questions not formatted
  for the screen size
- The device used can shift a participant's preference for scale type
- Visual analog scales (VAS) and slider scales can take longer to
  complete than radio-button alternatives
- Ordinal scales have been shown not to be equidistant, compared to
  continuous alternatives
- Slider/VAS scales may be less confounded by covariates and less prone
  to ceiling effects than Likert scales
- The starting placement of a slider button can bias the resulting
  distribution
- Numeric labeling on slider/VAS scales can lead to rounding by
  participants

Most of what's known here comes from standalone studies designed a priori
to test these specific questions. Large-scale, standardized, FAIR
description of UI elements would make it possible to run meta-analyses across 
studies already using the same scales in different forms and could open the door to exploratory analysis of UI elements that haven't been examined yet, since researchers 
are unlikely to study a UI element they have no a priori theoretical reason to expect matters.

## What to include

- **Screenshots** of each measurement tool, in its different states of
  interaction (e.g., no button pushed, one button pushed) — screenshots
  ensure every element of the UI is captured and none is left out of the
  description
- **Short video clips** for tools that are more interactive, such as
  mobile cognitive tests, where a static screenshot can't capture the
  interaction
- A description of the **possible devices** used to complete each
  assessment, since the same item can look and behave very differently
  on, say, a phone versus a laptop
- Screenshots can be generated via simulator or captured manually, making
  them relatively easy to fold into an existing data pipeline

## Generating UI documentation with WearITReadR

WearITReadR's screenshot scraper walks a study's block map (via
[Maestro Studio](https://maestro.dev/)) and captures screenshots
automatically, which can then be embedded directly into a generated
codebook. See [WearITReadR](../WearITReadR) for details.
