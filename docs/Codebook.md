---
title: Codebook
---

# Defining Codebooks 

Codebooks define the conceptual characteristics of the measurements, their relationships to other constructs, provenance, etc., and written in a more human-friendly way. We argue that this should include justification for design decisions that are related to the meaning or operationalization of constructs. For example,  

"We selected Happy, Joyful, and Cheery as the indicators for positive affect. These represent a subset of the PANAS positive affect scale (Watson, Clark, & Tellegen, 1988), and were selected because of their high loadings in prior work (e.g. Brick, et al., 2027). The overall PA score is derived as a mean of these three indicators, omitting missing values (code link). 

In contrast to data dictionaries, which may be associated with any data file, codebooks are most commonly used in conjunction with data files or databases that have been preprocessed (for example, to remove outliers and fix errors of data entry) and are ready for analysis. For this reason, codebooks are more commonly used by researchers to … .  

Note that the information in data dictionaries and codebooks overlaps significantly.  For example, both include some description of the mapping between the qualitative answers selected by participants and the numeric values that represent them in the data.    


# Codebook Layout

- **Title page**
  - Name of study
  - Authors
  - Any desired graphics
  - Funding Source



- **Abstract Page**
  - Brief description of study
  - Study aims
  - History, and date of data collection
  - Location of data collection
  - People involved and respective roles of those people
  - Who, what, where, when, + what did you do

 

- **Executive Summary (optional)**
  - Effectively a results page summarizing main findings of the study. May not be necessary for all studies, especially those without any results thus far and for large scale data collection ventures without any one main aim that can be confirmed by a few analyses, .... but strongly suggested?
  
  
   
- **Table of contents**



- **Variable pages**



- ***Text/name Elements***
  - Variable name
    - As it appears in the dataset
  - Human readable name
    - If it's a survey question
      - Exactly as it is presented to participant (if applicable)
    - If observational, or obtained from passive technology
      - Description of variable in layman’s term
        - If layman’s term not possible, citation of longer explanation of terms



- ***Paradata/ meta data Elements***
  - Skip Logic
    - For whom and when is this data collected
  - How the data was obtained
    - Sensing, survey, observation, circling something on page, digital slider etc.
  - Type of data
    - Numeric, categorical, continuous, etc.
  - Possible values of the data including items codes (1 = strongly disagree)
    - I.e. ranges from 0-10, 1-5 ranging from strongly disagree to strongly agree
  - Screenshot of question
  - Measurement citation
  - Distance between measurements (or perhaps just time of measurements then this can be displayed as a descriptive)
    - e.g. 1 day, 1 hour, (if complex, this will need to be described in the skip logic)
    - Hashtag momlife, FamBest

 

- ***Statistical Elements***
  - Descriptives of variable
    - Min, max, mean, std dev, # of valid observations
  - Report Missingness
  - Frequency of missingness
  - Structure of missingness
    - MAR, MNAR, MCAR
  - Report missingness...
    - Based on our developed standards depending on type of data (skip logic, triggered survey)
  - Icc, means, variability and missingness planned and unplanned range
  - Types of missingness
    - Refused, don’t know, not applicable, not ascertained
  - Code for types of missingness in data
    - 99999, -1, -5, -7, NA etc.
 
 

# Taxonomy
Nesting Structure



- Study
  - Burst
    - Survey
      - Block
        - Question
