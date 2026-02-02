#' Generate Survey Tree
#'
#' This generates a Survey Tree for a studies WearIT data
#'
#' @param blockMap Blockmap containing data for a single survey
#' @param shiny boolean indicating whether using shiny app
#' @return survey tree
#' @import visNetwork
#' @importFrom utils read.csv
#' @export

generateSurveyTree <- function(shiny = FALSE, blockMapParsed) {

  blockMap <- blockMapParsed

  # Initialize Node levels to track position of nodes
  nodeLevels <- setNames(rep(NA, nrow(blockMap)), blockMap$Item.ID)
  currentLevel <- 0

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

  edges <- data.frame(from = character(), to = character(), title = character())

  for (i in 1:nrow(blockMap)) {
    # Put initial child check
    if (blockMap$childTrue[i] == TRUE) {
      next
    }

    item <- blockMap[i,]

    # Draw node level
    if (is.na(nodeLevels[item$Item.ID])) {
      nodeLevels[item$Item.ID] <- currentLevel
      currentLevel <- currentLevel + 1
    }


    # Draw to next item that isnt child
    lowerRows <- blockMap[i+1:nrow(blockMap),]
    lowerRows <- lowerRows[lowerRows$childTrue == FALSE,]
    edges <- rbind(edges, data.frame(from = item$Item.ID, to = lowerRows$Item.ID[1], label = ""))


    # If conditionals, draw them
    if (!is.na(item$Conditional.Child.Item.ID) | !is.na(item$Conditional.Fail.Item.ID)) {
      # Draw to conditionals

        parentLevel <- nodeLevels[item$Item.ID]

        # Child
        childID <- paste0("Item ", item$Conditional.Child.Item.ID)
        edges <- rbind(edges, data.frame(from = item$Item.ID, to = childID, label = "Child"))
        nodeLevels[childID] <- parentLevel + .5


        # Fail
        failID <- paste0("Item ", item$Conditional.Fail.Item.ID)
        edges <- rbind(edges, data.frame(from = item$Item.ID, to = failID, label = "Fail"))
        nodeLevels[failID] <- parentLevel + .5

      # Walk the conditionals
      # Grab child
      child <- blockMap[blockMap$Item.ID == paste0("Item ", item$Conditional.Child.Item.ID),]

      while (nrow(child) > 0 && (!is.na(child$Conditional.Child.Item.ID) | !is.na(child$Conditional.Fail.Item.ID))) {
        # Draw to conditionals

        childParentLevel <- nodeLevels[child$Item.ID]

        # Child
        nestedChildID <- paste0("Item ", child$Conditional.Child.Item.ID)
        edges <- rbind(edges, data.frame(from = child$Item.ID, to = nestedChildID, label = "Child"))
        nodeLevels[nestedChildID] <- childParentLevel + .5

        # Fail
        nestedFailID <- paste0("Item ", item$Conditional.Fail.Item.ID)
        edges <- rbind(edges, data.frame(from = child$Item.ID, to = nestedFailID, label = "Fail"))
        nodeLevels[nestedFailID] <- childParentLevel + .5

        # Go to next child
        child <- blockMap[blockMap$Item.ID == paste0("Item ", child$Conditional.Child.Item.ID),]
      }
    }
  }

  edges <- unique(edges)

  nodes <- data.frame(id = blockMap$Item.ID,
                      label = blockMap$Item.ID,
                      title = blockMap$Question.Text,
                      level = nodeLevels[blockMap$Item.ID])

  #edges <- data.frame(from = blockMap$Item.ID, to = c(blockMap$Item.ID[-1], NA))
  title <- paste0("Flowchart of Survey: ", unique(blockMap$Survey.LongName))
  visNetwork(nodes, edges, main = title) %>%
    visEdges(arrows = "to") %>%
    visHierarchicalLayout(
      direction = "LR",
      sortMethod = "directed"
    ) %>%
    visPhysics(
      enabled = TRUE,
      stabilization = FALSE  # Disable initial stabilization
    ) %>%
    visInteraction(dragNodes = TRUE, dragView = TRUE) %>%
    visOptions(manipulation = FALSE)
}


