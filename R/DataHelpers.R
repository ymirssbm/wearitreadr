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

parseBySurvey <- function(blockMap, survey, all = FALSE) {

  # Parse by survey
  if (all == TRUE) {
    surveys <- unique(blockMap$Survey)
    for (survey in surveys) {
      next
    }
  } else {
    blockMapParsed <- blockMap[blockMap$Survey == survey & !is.na(blockMap$Survey),]
  }

  return(blockMapParsed)

}




#' saveData
#'
#'   This is a wrapper on getStudyData that saves it to the data folder
#'
#' @param data data object to save from
#' @param pull whether to pull data from wearIt before saving
#' @param skip_readline Boolean indicating whether the user is in the shiny app and wants to skip readline for api key
#' @return Saves data to data folder in codebook rmd


saveData <- function(data = NULL, pull = FALSE, ...) {

  if (pull == TRUE) {
    data <- getStudyData(...)
  }

  write.csv(data$questionMap, "blockMap.csv", row.names = FALSE)
  write.csv(data$responseMap, "responseKey.csv", row.names = FALSE)
  write.csv(data$surveyCombined, "Data.csv", row.names = FALSE)

  return(invisible(NULL))
}



#' loadSavedData
#'
#' This loads all WearIT data
#'
#' @param shiny Boolean indicating whether the user is in the shiny app or not
#' @return blockMap Data and responseKey in environment

loadSavedData <- function() {
    blockMap <<- read.csv(get_resource_path("Codebook_RMD", "Data", "blockMap.csv"))
    Data <<- read.csv(get_resource_path("Codebook_RMD", "Data", "Data.csv"))
    responseKey <<- read.csv(get_resource_path("Codebook_RMD", "Data", "responseKey.csv"))

  return(invisible(NULL))
}
