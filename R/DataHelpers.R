#' Parse by Survey
#'
#' This helps grab a blockMap for a single survey.
#'
#' @param shiny Boolean indicating whether using shiny app
#' @param survey Name of the survey to pull ex. "Daily Diary"
#' @param all Whether to pull a different blockMap for each survey... not implemented yet
#' @return A block map for a given "survey"
#' @importFrom utils read.csv
#' @export

parseBySurvey <- function(shiny = FALSE, survey, all = FALSE) {

  if (shiny==FALSE) {
    blockMap <- read.csv("codebookApp/Codebook_RMD/Data/blockMap.csv")
  }
  if (shiny==TRUE) {
    blockMap <- read.csv("Codebook_RMD/Data/blockMap.csv")
  }

  # Parse by survey
  if (all == TRUE) {
    surveys <- unique(blockMap$Survey.LongName)
    for (survey in surveys) {
      next
    }
  } else {
    blockMapParsed <- blockMap[blockMap$Survey.LongName == survey & !is.na(blockMap$Survey.LongName),]
  }

  return(blockMapParsed)

}







#' saveData
#'
#'   This is a wrapper on getStudyData that saves it to the data folder
#'
#' @param data data object to save from
#' @param pull whether to pull data from wearIt before saving
#' @param shiny Boolean indicating whether the user is in the shiny app or not
#' @return Saves data to data folder in codebook rmd


saveData <- function(data, shiny = FALSE, pull = FALSE, ...) {

  if (pull == TRUE) {
    data <- getStudyData(shiny = shiny, ...)
  }


  if (shiny == TRUE) {
    write.csv(data$questionMap, "Codebook_RMD/Data/blockMap.csv", row.names = FALSE)
    write.csv(data$responseMap, "Codebook_RMD/Data/responseKey.csv", row.names = FALSE)
    #write.csv(data$surveyData, "Codebook_RMD/Data/surveyData.csv", row.names = FALSE)
    write.csv(data$surveyCombined, "Codebook_RMD/Data/Data.csv", row.names = FALSE)
  }

  if (shiny == FALSE) {
    write.csv(data$questionMap, "codebookApp/Codebook_RMD/Data/blockMap.csv", row.names = FALSE)
    write.csv(data$responseMap, "codebookApp/Codebook_RMD/Data/responseKey.csv", row.names = FALSE)
    #write.csv(data$surveyData, "Codebook_RMD/Data/surveyData.csv", row.names = FALSE)
    write.csv(data$surveyCombined, "codebookApp/Codebook_RMD/Data/Data.csv", row.names = FALSE)
  }
}



#' loadSavedData
#'
#' This loads all WearIT data
#'
#' @param shiny Boolean indicating whether the user is in the shiny app or not
#' @return blockMap Data and responseKey in environment

loadSavedData <- function(shiny = FALSE) {
  if (shiny == TRUE) {
    blockMap <<- read.csv("Codebook_RMD/Data/blockMap.csv")
    Data <<- read.csv("Codebook_RMD/Data/Data.csv")
    responseKey <<- read.csv("Codebook_RMD/Data/responseKey.csv")
  }

  if (shiny == FALSE) {
    blockMap <<- read.csv("codebookApp/Codebook_RMD/Data/blockMap.csv")
    Data <<- read.csv("codebookApp/Codebook_RMD/Data/Data.csv")
    responseKey <<- read.csv("codebookApp/Codebook_RMD/Data/responseKey.csv")
  }
  return(blockMap)
}

