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


# GLP-1 data
creds <- wearIT_authorize(study_ID = "2027", base_URL = "https://wearables.vmhost.psu.edu/wearables-survey_sdb/api",
                          key_name="WearIT-API-key-sdb",
                          backup_key_file = "~/.auth/.wearit_sdb",
                          skip_keyring = FALSE)
requestResults <- makeAllRequests(creds)
studyData <- parseStudyJSON(requestResults, simpleMeta = TRUE, metaCount = 1)

for (name in names(studyData)) {
  write.csv(studyData[[name]], file = file.path("processedData/", paste0(name, ".csv")), row.names = FALSE)
}


data <- studyData$surveyCombined
write.csv(data, file = file.path("processedData/surveyCombined.csv"), row.names = FALSE)
