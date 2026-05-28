#' Generate Data Dictionary
#'
#' This generates a data dictionary for a studies WearIT data
#'
#' @return datadictionary.csv file in Codebook_RMD folder
#' @importFrom dplyr arrange
#' @export


generateDataDictionary <- function(blockMap = read.csv(get_resource_path("Codebook_RMD", "Data", "blockMap.csv")),
                                   responseKey = read.csv(get_resource_path("Codebook_RMD", "Data", "responseKey.csv")),
                                   ...) {


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
  blockMap <- blockMap[, intersect(c("Survey", "Question.ID", "Question.Text",
                                     "Question.Type.Display.Name", "Result.Type",
                                     "Missingness.Codes", "Response.Range", "Response.Text"),
                                   colnames(blockMap))]
  blockMap <- blockMap[rowSums(is.na(blockMap)) != ncol(blockMap), ]
  colnames(blockMap)[colnames(blockMap) == "Survey"] <- "Survey.LongName"
  write.csv(blockMap, get_resource_path("Codebook_RMD", "DataDictionary.csv"), row.names = FALSE)

}
