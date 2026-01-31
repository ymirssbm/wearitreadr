#' Generate Data Dictionary
#'
#' This generates a data dictionary for a studies WearIT data
#'
#' @return datadictionary.csv file in Codebook_RMD folder
#' @export


generateDataDictionary <- function(data = read.csv("Codebook_RMD/Data/blockMap.csv"), shiny = FALSE) {

  if (shiny == TRUE) {
    write.csv(data, "Codebook_RMD/DataDictionary.csv")
  }

  if (shiny == FALSE) {
    write.csv(data, "DataDictionary.csv")
  }
}
