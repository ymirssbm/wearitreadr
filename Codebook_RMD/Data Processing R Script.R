#################
# This script is for Ethan to develop codebook generation
#################


# Source processdata

source("../R/ProcessData.R")





# Load in block types
load("~/R/Tim Lab/GIT R directory/wearitreadr/data/WearIT.blockTypes.rda")

# Pull study data
studyData <- getStudyData()


for (name in names(studyData)) {
  write.csv(studyData[[name]], file = file.path("processedData", paste0(name, ".csv")), row.names = FALSE)
}
