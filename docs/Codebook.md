# Codebook Requirements



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
