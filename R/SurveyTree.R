#' Generate Survey Tree
#'
#' This generates a Survey Tree for a studies WearIT data
#'
#' @param blockMap Blockmap containing data for a single survey
#' @param shiny boolean indicating whether using shiny app
#' @return Mermaid flowchart
#' @import DiagrammeR
#' @importFrom utils read.csv
#' @export


# Logic structure

# If block, draw block and draw down (this works because the blocks are sorted and placed at the top of their sections)

# If question, do these 3 checks

# 1.) If its neither a parent nor a child, draw to the next row
# 2.) If its a parent AT all, regardless of child status, draw to only the conditional (mark its a parent so I can draw conditional step)
# 3.) If its a child but not a parent, go to next row that is not a child
# NOTE child status refers to, whether it is a child of a ITEM not a BLOCK


generateSurveyTree <- function(shiny = FALSE, blockMapParsed) {

  #blockMap <- blockMap[blockMap$Survey == "CSAR Daily Diary ID 35" & !is.na(blockMap$Survey),]
  blockMap <- blockMapParsed

  # File the blocks into the right position of the blockmap
  # Separate blocks from questions
  blocks <- blockMap[blockMap$Item.Type == "Block", ]
  questions <- blockMap[blockMap$Item.Type != "Block", ]

  # For each block, find where it belongs and insert it
  result <- data.frame()

  i <- 1
  while (i <= nrow(questions)) {
    current_row <- questions[i, ]

    # Check if any block is the parent of this row
    matching_block <- blocks[blocks$Item.ID == current_row$Parent, ]

    if (nrow(matching_block) > 0) {
      # Check we haven't already inserted this block
      if (!matching_block$Item.ID %in% result$Item.ID) {
        result <- rbind(result, matching_block)
      }
    }

    result <- rbind(result, current_row)
    i <- i + 1
  }

  blockMap <- result

  blockMap$childTrue  <- NA
  blockMap$parentTrue <- NA

  # Create boolean cols for child status (questions only)
  for (i in 1:nrow(blockMap)) {
    if (blockMap$Item.Type[i] == "Block") {
      blockMap$childTrue[i] <- FALSE
    } else {
      if (substring(blockMap$Item.ID[i], 6) %in% blockMap$Conditional.Child.Item.ID) {
        blockMap$childTrue[i] <- TRUE
      } else {
        blockMap$childTrue[i] <- FALSE
      }
    }
  }

  # Create boolean cols for parent status (questions only)
  for (i in 1:nrow(blockMap)) {
    if (blockMap$Item.Type[i] == "Block") {
      blockMap$parentTrue[i] <- FALSE
    } else {
      if (!is.na(blockMap$Conditional.Child.Item.ID[i]) &&
          !is.na(blockMap$Conditional.Fail.Item.ID[i])) {
        blockMap$parentTrue[i] <- TRUE
      } else {
        blockMap$parentTrue[i] <- FALSE
      }
    }
  }

  # Initialize df to store flowchart info
  flowchart <- data.frame(
    from = character(),
    to = character(),
    to2 = character(),
    parent = logical()
  )



  # Logic structure

  # If block, draw block and draw down (this works because the blocks are sorted and placed at the top of their sections)

  # If question, do these 3 checks

  # 1.) If its neither a parent nor a child, draw to the next row
  # 2.) If its a parent AT all, regardless of child status, draw to only the conditional (mark its a parent so I can draw conditional step)
  # 3.) If its a child but not a parent, go to next row that is not a child
  # NOTE child status refers to, whether it is a child of a ITEM not a BLOCK

  for (i in 1:nrow(blockMap)) {
    # 1.)
    if (blockMap$parentTrue[i] == FALSE && blockMap$childTrue[i] == FALSE) {
      flowchart <- rbind(flowchart, data.frame(from = blockMap$Item.ID[i],
                                               to = blockMap$Item.ID[i+1],
                                               to2 = NA,
                                               parent = FALSE))
    }
    # 2.)
    if (blockMap$parentTrue[i] == TRUE) {
      flowchart <- rbind(flowchart, data.frame(from = blockMap$Item.ID[i],
                                               to = paste0("Item ", blockMap$Conditional.Child.Item.ID[i]),
                                               to2 = paste0("Item ", blockMap$Conditional.Fail.Item.ID[i]),
                                               parent = TRUE))
    }
    # 3.)
    if (blockMap$childTrue[i] == TRUE && blockMap$parentTrue[i] == FALSE) {
      # Pull down just the current item onwards
      temp <- blockMap[i:nrow(blockMap),]
      flowchart <- rbind(flowchart, data.frame(from = blockMap$Item.ID[i],
                                               to = temp[which(temp$childTrue == FALSE, arr.ind = TRUE)[1],]$Item.ID,
                                               to2 = NA,
                                               parent = FALSE))
    }
  }

  # NOTE here, "to2" is a little silly, but it makes sense and sets up later

  # I think I can just do this, this basically just gets rid of drawing a path to nowhere when the survey is done
  flowchart <- flowchart[!is.na(flowchart$to), ]

  # Build mermaid syntax
  flowchart_syntax <- "graph LR"

  for (i in 1:nrow(flowchart)) {
    current <- flowchart[i,]
    # If parent draw decision node, else just regular path
    if (current$parent) {

      lines <- c(
        # Draw to decision
        paste0(gsub(" ", "_",current$from),"[",current$from,"] --> ", "decision",i,"{ }"),
        # Draw from decision node
        paste0("decision",i,"{ } --> ", gsub(" ", "_", current$to),"[",current$to,"]"),
        paste0("decision",i,"{ } --> ", gsub(" ", "_", current$to2),"[",current$to2,"]")
      )

      flowchart_syntax <- paste(
        c(flowchart_syntax, lines),
        collapse = "\n"
      )
    } else {
      lines <- c(paste0(gsub(" ", "_",current$from),"[",current$from,"] --> ", gsub(" ", "_", current$to), "[",current$to,"]"))
      flowchart_syntax <- paste(
        c(flowchart_syntax, lines),
        collapse = "\n"
      )
    }
  }

  # Draw flowchart
  if (shiny) {
    return(flowchart_syntax)
  } else {
    mermaid(flowchart_syntax)
  }
}


