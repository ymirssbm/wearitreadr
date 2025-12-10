source("~/R/Tim Lab/GIT R directory/wearitreadr/R/ProcessData.R")


# Write each data frame in 'data' to a CSV file named after its name
write.csv(studyData$questionMap, "questionMap.csv", row.names = FALSE)
write.csv(studyData$responseMap, "responseMap.csv", row.names = FALSE)
write.csv(studyData$surveyData, "surveyData.csv", row.names = FALSE)
write.csv(studyData$surveyCombined, "surveyCombined.csv", row.names = FALSE)

