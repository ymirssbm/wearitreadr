setwd("~/R/GitHub Projects/wearitreadr/Codebook_RMD")
rm(list = ls())
#devtools::document()
devtools::load_all()

generateCodebook()




# GLP-1 Codebook
generateCodebook(
  title = "UH3 GLP-1 Codebook",
  authors = "Ethan O. Kile, Timothy R. Brick",
  funding = "Sponsor: Milton S. Hershey Medical Center",
  abstract =
  "The goal of this clinical trial is to learn if semaglutide can reduce illicit opioid use in adults in outpatient treatment for opioid use disorder, and who are receiving either buprenorphine or methadone maintenance treatment. The main question it aims to answer is:

    • Does semaglutide increase the likelihood that participants will refrain from using illicit and nonprescribed opioids?

  The investigators will compare semaglutide to a placebo (a needle prick that contains no drug) to see if semaglutide works to reduce use of illicit and nonprescribed opioids.

  The participants will:
    Take semaglutide or a placebo every week for 12 weeks
    Visit the clinic every week for urine drug screening and pregnancy testing, vital signs, and to complete mental health and drug use questionnaires
    Complete smartphone surveys sent at set times during the study",
  summary = "This study is still in data collection and therefore has no findings to report at this time.",
  output_file = "UH3 GLP-1 EMA Codebook")


# RCC RG combined

thisData = read.csv("rccRgData/surveyCombined.csv")
blockMap = read.csv("rccRgData/questionMap.csv")
responseKey = read.csv("rccRgData/responseMap.csv")

rccthisData = read.csv("rccRgData/rccsurveyCombined.csv")
rccblockMap = read.csv("rccRgData/rccquestionMap.csv")
rccresponseKey = read.csv("rccRgData/rccresponseMap.csv")


df <- merge(blockMap, rccblockMap, by = "Question.Text")


# Find new block map questions
new_questions <- rccblockMap[!rccblockMap$Question.Text %in% blockMap$Question.Text, ]

# Bind them together
mergedMap <- rbind(blockMap, new_questions)


# Grab new question ids to bind response key
question_ids <- new_questions$Question.ID

new_question_map <- rccresponseKey[rccresponseKey$question %in% question_ids,]

responseKey <- rbind(responseKey, new_question_map)

# Merge data
# Step 1: Create lookup table from thisData with unique Question.Text and IDs
lookup_ids <- thisData %>%
  select(Question.Text, Question.ID, Item) %>%
  distinct(Question.Text, .keep_all = TRUE)

# Step 2: Update rccthisData's Question.ID and Item based on Question.Text
rccthisData <- rccthisData %>%
  select(-Question.ID, -Item) %>%       # Remove old columns
  left_join(lookup_ids, by = "Question.Text")  # Bring in correct IDs

rccthisData <- rccthisData %>% select(-"External.ID3")

col_order <- colnames(thisData)
rccthisData <- rccthisData[, col_order]

df <- rbind(thisData, rccthisData)

# Write each data frame in 'data' to a CSV file named after its name
write.csv(mergedMap, "processedData/questionMap.csv", row.names = FALSE)
write.csv(responseKey, "processedData/responseMap.csv", row.names = FALSE)
#write.csv(data$surveyData, "processedData/surveyData.csv", row.names = FALSE)
write.csv(df, "processedData/surveyCombined.csv", row.names = FALSE)


# GLP-1 Codebook
generateCodebook(
  title = "Recovery Community Center and Recovery General Combined Codebook",
  authors = "Ethan O. Kile, Timothy R. Brick",
  funding = "",
  abstract = "",
  summary = "",
  generate_item_description = FALSE,
  output_file = "rccRgCodebook")
