
library(visNetwork)

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


#' Generate Survey Tree
#'
#' This generates a Survey Tree for a studies WearIT data
#'
#' @return survey tree
#' @import visNetwork
#' @importFrom utils read.csv
#' @export

generateSurveyTree <- function(shiny = FALSE, blockMap = blockMapParsed) {

  nodes <- data.frame(id = blockMap$Item.ID, label = blockMap$Item.ID, title = blockMap$Question.Text)
  edges <- data.frame(from = blockMap$Item.ID, to = c(blockMap$Item.ID[-1], NA))
  title <- paste0("Flowchart of Survey: ", unique(blockMap$Survey.LongName))
  visNetwork(nodes, edges, main = title) %>% visEdges(arrows = "to") %>% visHierarchicalLayout(direction = "LR")
}
