#' Generate Data Dictionary
#'
#' This generates a data dictionary for a studies WearIT data
#'
#' @return datadictionary.csv file in Codebook_RMD folder
#' @importFrom dplyr arrange
#' @export


generateDataDictionary <- function(blockMap = read.csv("Codebook_RMD/Data/blockMap.csv"),
                                   responseKey = read.csv("Codebook_RMD/Data/responseKey.csv"),
                                   ..., shiny = FALSE) {


  # Missingness codes dont exists yet so initialize it and later bind to blockMap
  Missingness.Codes <- rep(NA, nrow(blockMap))

  Response.Text <- rep(NA, nrow(blockMap))
  Response.Range <- rep(NA, nrow(blockMap))

  # Grab all the info we need from response map for each question
  for (i in 1:nrow(blockMap)) {
    question_id <- blockMap$Question.ID[i]
    if (question_id %in% responseKey$question) {
      question_rows <- responseKey[responseKey$question == question_id & responseKey$type == "Response",]
      question_rows <- arrange(question_rows, value)
      min_response <- min(question_rows$value, na.rm = TRUE)
      max_response <- max(question_rows$value, na.rm = TRUE)
      Response.Text[i] <- paste(question_rows$definition, collapse = ", ")
      Response.Range[i] <- paste0(min_response, " - ", max_response)
      } else {
        Response.Text[i] <- NA
        Response.Range[i] <- NA
    }
  }


  blockMap <- cbind(blockMap, Missingness.Codes, Response.Range, Response.Text)
  blockMap <- blockMap[, c("Survey.LongName", "Question.ID", "Question.Text", "Question.Type.Display.Name", "Result.Type", "Missingness.Codes", "Response.Range", "Response.Text")]
  blockMap <- blockMap[rowSums(is.na(blockMap)) != ncol(blockMap), ]

  if (shiny == TRUE) {
    write.csv(blockMap, "Codebook_RMD/DataDictionary.csv", row.names = FALSE)
  }

  if (shiny == FALSE) {
    write.csv(blockMap, "DataDictionary.csv", row.names = FALSE)
  }
}
