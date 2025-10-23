source("~/R/Tim Lab/GIT R directory/wearitreadr/R/ProcessData.R")
data <- getStudyData(study_ID = "1057")

# Write each data frame in 'data' to a CSV file named after its name
write.csv(data$questionMap, "questionMap.csv", row.names = FALSE)
write.csv(data$responseMap, "responseMap.csv", row.names = FALSE)
write.csv(data$surveyData, "surveyData.csv", row.names = FALSE)
write.csv(data$surveyCombined, "surveyCombined.csv", row.names = FALSE)

data <- getStudyData(study_ID = "1045")
# Write each data frame in 'data' to a CSV file named after its name
write.csv(data$questionMap, "rccquestionMap.csv", row.names = FALSE)
write.csv(data$responseMap, "rccresponseMap.csv", row.names = FALSE)
write.csv(data$surveyData, "rccsurveyData.csv", row.names = FALSE)
write.csv(data$surveyCombined, "rccsurveyCombined.csv", row.names = FALSE)


