# WearIT Codebook Generator

WearITReadR repo contains a shiny app and open source R package that is currently in development. functionality includes... WearIT (smartphone EMA data collection app) api pull, customizable codebook, data dictionary, and study flow chart generator, AI study generator and modifier which generates JSON following my data description and storage spec, a screenshot scraper which walks a study block map to generate YAML to walk a study and scrape screenshots (which then can be embedded inside a generated codebook) as well as a Qualtrics translator which translates from Qualtrics API to our internal JSON storage then parses it. This allows us to generate all of the things mentioned from Qualtrics surveys. See examples folder in the WearITReadR repo

NOTE: Screenshot scraper and Qualtrics translator have yet to be implemented into the Shiny app. 

<img width="1918" height="927" alt="wearitreadr screenshot" src="https://github.com/user-attachments/assets/55036984-d4a0-4b79-93cb-91ea6b54db4e" />

## Link to Codebook Example from a Recovery Community Center Project

🔗 [View Codebook Example (RCC Project)](https://ymirssbm.github.io/wearitreadr/Examples/Recovery%20Community%20Center%20(RCC)%20Project/Codebook.html)

## Recovery Community Center Project Study Flowchart

![Flowchart](https://raw.githubusercontent.com/ymirssbm/wearitreadr/main/Examples/Recovery%20Community%20Center%20(RCC)%20Project/flowchart.png)

## How to run

devtools:load_all() -> wearitreadr()

## Urgent TDL

## Known Issues / To do list

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

## Contributers

Ethan O. Kile - eok5206@psu.edu

Timothy R. Brick - tbrick@psu.edu
