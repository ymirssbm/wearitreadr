# Set wd, load all and clear environment
library(rstudioapi)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
rm(list = ls())
devtools::load_all(recompile = FALSE)
devtools::document()

# Pull data from api
data <- getStudyData(study_ID = "1045")

# Save it to processedData folder in Codebook_RMD
saveData(data)

# Generate codebook
generateCodebook()

# Running App
wearitreadr()
