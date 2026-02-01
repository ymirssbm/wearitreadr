
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

  blockMap <- blockMapParsed

  newCols <- c("parentTrue", "childTrue")
  blockMap[,newCols] <- NA

  # Create boolean cols for child status
  for (i in 1:nrow(blockMap)) {
    if (substring(blockMap$Item.ID[i], 6) %in% blockMap$Conditional.Child.Item.ID) {
      blockMap$childTrue[i] <- TRUE
    } else {
      blockMap$childTrue[i] <- FALSE
    }
  }

  edges <- data.frame(from = character(), to = character())

  for (i in 1:nrow(blockMap)) {
    # Put initial child check
    if (blockMap$childTrue[i] == TRUE) {
      next
    }

    item <- blockMap[i,]

    # Draw to next item that isnt child
    lowerRows <- blockMap[i+1:nrow(blockMap),]
    lowerRows <- lowerRows[lowerRows$childTrue == FALSE,]
    edges <- rbind(edges, data.frame(from = item$Item.ID, to = lowerRows$Item.ID[1]))


    # If conditionals, draw them
    if (!is.na(item$Conditional.Child.Item.ID) | !is.na(item$Conditional.Fail.Item.ID)) {
      # Draw to conditionals
      edges <- rbind(edges, data.frame(from = item$Item.ID, to = paste0("Item ", item$Conditional.Child.Item.ID)))
      edges <- rbind(edges, data.frame(from = item$Item.ID, to = paste0("Item ", item$Conditional.Fail.Item.ID)))

      # Walk the conditionals
      # child <- blockMap[blockMap$Item.ID == paste0("Item ", item$Conditional.Fail.Item.ID)]
    }
  }

  # edges <- unique(edges)

  nodes <- data.frame(id = blockMap$Item.ID, label = blockMap$Item.ID, title = blockMap$Question.Text)

  #edges <- data.frame(from = blockMap$Item.ID, to = c(blockMap$Item.ID[-1], NA))
  title <- paste0("Flowchart of Survey: ", unique(blockMap$Survey.LongName))
  visNetwork(nodes, edges, main = title) %>%
    visEdges(arrows = "to") %>%
    visHierarchicalLayout(direction = "LR", sortMethod = "directed")
}


