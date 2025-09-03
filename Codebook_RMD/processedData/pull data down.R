data <- getStudyData(study_ID = "1009")

# Write each data frame in 'data' to a CSV file named after its name
write.csv(data$questionMap, "questionMap.csv", row.names = FALSE)
write.csv(data$responseMap, "responseMap.csv", row.names = FALSE)
write.csv(data$surveyData, "surveyData.csv", row.names = FALSE)
write.csv(data$surveyCombined, "surveyCombined.csv", row.names = FALSE)


test <- data$questionMap
