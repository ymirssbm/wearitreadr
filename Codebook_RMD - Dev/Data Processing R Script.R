#################
# This script is for Ethan to develop codebook generation
#################


# Source processdata

source("../R/ProcessData.R")





# Load in block types
load("~/R/Tim Lab/GIT R directory/wearitreadr/data/WearIT.blockTypes.rda")

# Pull study data
#debug(getStudyData)

studyData <- getStudyData(study_ID = "1009")


for (name in names(studyData)) {
  write.csv(studyData[[name]], file = file.path("processedData", paste0(name, ".csv")), row.names = FALSE)
}

library(rmarkdown)

debug(render)
render("Highest-level-template.Rmd", output_format = "html_document")

debug(knit)
knit("Highest-level-template.Rmd")
