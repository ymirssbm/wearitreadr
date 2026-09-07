# WearITReadR Codebook Generator and Data Documentation Tool for Wear-IT

## What is WearITReadR

WearITReadR repo contains a shiny app and open source R package that is currently in development. Functionality includes... Wear-IT (smartphone EMA data collection app) api pull, customizable codebook, data dictionary, and study flow chart generator, AI study generator and modifier which generates JSON following the WearITReadR's data description and storage spec, a screenshot scraper which walks a study block map to generate YAML to walk a study and scrape screenshots (which then can be embedded inside a generated codebook) as well as a Qualtrics translator which translates from Qualtrics API to our internal JSON storage then parses it. This allows us to generate all of the things mentioned from Qualtrics surveys. See examples folder in the WearITReadR repo

Accompanying the WearITReadR app, is a JSON specification that acts as an initial draft of a data description standard for complex study designs (see inst/schema/0.1.0/study.json).

## Using WearITReadR with other data collection apps

Although this tool is designed primarily to interface with Wear-IT's API, it can be adapted to work with other data collection API's as well. To proof of concept this, we successfully vibe coded a simple translator that translates studies ran on Qualtrics to WearITReadR using API translator function. This allows us to use any of the features from the WearITReadR app for any studies ran on Qualtrics. We intentionally employed vibe coding for this part of the project to demonstrate that even researchers with limited technical ability could quickly build API translators from their preferred data collection apps to the Wear-IT api so that they could use the WearITReadR's many functionalities on their own datasets. All in all the process of building a translator leveraging generative AI only took a couple minutes.

Theoretically similar translators could be built for any data collection API or software. Since the WearITReadR app utilizes a JSON specification, it is relatively easy to build and test API translators. One of the benefit of using JSON is the availability of JSON validators which allow us, as well as, generative AI, to formally test whether an ingested JSON follows a required JSON specification. If the ingested JSON does not follow the format of the JSON specification, then it will throw an informative error. This makes the process of building translators from generative AI increasingly seamless as these models can test whether, where and how a translator is failing and correct it. 

NOTE: Study screenshot scraper and Qualtrics translator have yet to be implemented into the Shiny app. Both are currently implemented as R functions with the study screenshot scraper also requiring the use of Maestro Studio. 

<img width="1918" height="927" alt="wearitreadr screenshot" src="https://github.com/user-attachments/assets/55036984-d4a0-4b79-93cb-91ea6b54db4e" />

# Examples of WearITReadR Functionality

This section includes a few examples of the WearITReadR's functionality. This section includes a Codebook generated from a real study as well as accompanying study flowchart, as well as a data dictionary for a study generated using the WearITReadR's AI study generator assistant. Additionally... See the "Examples" folder for more examples of the AI study generation, the qualtrics translator and more. 

## Link to Codebook Generated Using WearITReadR from the "Recovery Community Center Project"

🔗 [View Codebook Example (RCC Project)](https://ymirssbm.github.io/wearitreadr/Examples/Recovery%20Community%20Center%20(RCC)%20Project/Codebook.html)

## "Recovery Community Center Project" Study Flowchart

![Flowchart](https://raw.githubusercontent.com/ymirssbm/wearitreadr/main/Examples/Recovery%20Community%20Center%20(RCC)%20Project/flowchart.png)

## Link to Data Dictionary for a AI Generated Study

📄 [Data Dictionary (CSV)](https://github.com/ymirssbm/wearitreadr/blob/main/Examples/AI%20Generated%20Study%20Example/DataDictionary.csv)

# How to run WearITReadR in R

devtools:load_all()
wearitreadr()

# Urgent TDL

# Known Issues / To do list

- Add simple conditional column to Data dictionary 
- Fix multiple slider generation
- Need to be able to specify file name
- Missingness codes
- Survey beeps
- Figure out how to fix TOC when the first item in a survey is not a block
- Citations for scales
- Scale metadata
- Create data manual generation tool
- Dispatch model for AI generator
- For survey tree, display additional info on clicking node
- Figure out where the header for a slider histogram is drawn

# Citations

v0.1.0  ymirssbm/wearitreadr: WearITReadR
DOI: 10.5281/zenodo.22060584 

# Contributers

Ethan O. Kile - eok5206@psu.edu

Timothy R. Brick - tbrick@psu.edu
