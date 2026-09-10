---
layout: default
title: Your Page Title
nav_order: 1
---

# Defining Data Dictionaries 

Data dictionaries describe the information needed to decode and model each data file. That means data types, encoding of any categorical or missingness codes, valid and invalid value lists, and any provenance required for understanding (e.g. that these response times are log-transformed).  An example entry might read:  

> Happy | Likert 3-point | -1:Unhappy, 0:Neither happy nor unhappy, 1: Happy // PA | Continuous Derived | Range -1:1).  

Data dictionaries tend to be designed for technological use, and the dictionary for a data file is often stored as a single table in a database or a single spreadsheet file. Data dictionaries help to detail the structure of the respective data files (Buchanan et al., n.d.). Data management teams use data dictionaries to transform raw data files into usable databases in order to reproduce analyses or verify descriptive statistics; they may also serve researchers as quick-reference guides when working from a data file. Conversely, a well maintained and documented database will contain enough information to be transformed back into raw data and data dictionary files.  

# Data Dictionary Requirements
