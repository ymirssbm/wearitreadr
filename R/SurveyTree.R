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


generateSurveyTree <- function(shiny = FALSE, blockMapParsed, responseKey) {

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


  # Sort so conditional children appear after their master
  master_order <- which(!is.na(blockMap$Conditional.Master.Item.ID))
  for (i in master_order) {
    master_id <- paste0("Item ", blockMap$Conditional.Master.Item.ID[i])
    master_row <- which(blockMap$Item.ID == master_id)
    if (length(master_row) > 0 && master_row > i) {
      # Child is above its master — move child to just below master
      child_row <- blockMap[i, ]
      blockMap <- blockMap[-i, ]
      # Recalculate master position after removal
      master_row <- which(blockMap$Item.ID == master_id)
      blockMap <- rbind(
        blockMap[1:master_row, ],
        child_row,
        if (master_row < nrow(blockMap)) blockMap[(master_row+1):nrow(blockMap), ] else NULL
      )
    }
  }

  # Sort so conditional fail items appear after the row that references them
  fail_refs <- which(!is.na(blockMap$Conditional.Fail.Item.ID))
  for (i in fail_refs) {
    fail_id <- paste0("Item ", blockMap$Conditional.Fail.Item.ID[i])
    fail_row <- which(blockMap$Item.ID == fail_id)
    if (length(fail_row) > 0 && fail_row < i) {
      # Fail item is above the row referencing it — move it to just below
      fail_item <- blockMap[fail_row, ]
      blockMap <- blockMap[-fail_row, ]
      # Recalculate reference row position after removal
      i <- which(blockMap$Item.ID == blockMap$Item.ID[i])
      blockMap <- rbind(
        blockMap[1:i, ],
        fail_item,
        if (i < nrow(blockMap)) blockMap[(i+1):nrow(blockMap), ] else NULL
      )
    }
  }

  blockMap <- blockMap[!duplicated(blockMap[, !colnames(blockMap) %in% "Question.Type.Display.Name"]), ]

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

  # NOTE something is only a child, if its a child conditional, fails are not children.
  # Additionally, blocks are FALSE on both parent and child. So these refer to QUESTIONS not BLOCKS

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

  # 1.) If its neither a parent nor a child, draw to the next row that isnt a child since childs are only products of parents
  # 2.) If its a parent AT all, regardless of child status, draw to only the conditional (mark its a parent so I can draw conditional step)
  # 3.) If its a child but not a parent, go to next row that is not a child starting from the conditional master (starting from conditional master solves sorting problems)
  # NOTE child status refers to, whether it is a child of a ITEM not a BLOCK

  for (i in 1:nrow(blockMap)) {
    # 1.)
    if (blockMap$parentTrue[i] == FALSE && blockMap$childTrue[i] == FALSE) {
      temp <- blockMap[(i+1):nrow(blockMap), ]

      flowchart <- rbind(flowchart, data.frame(from = blockMap$Item.ID[i],
                                               to = temp[which(temp$childTrue == FALSE, arr.ind = TRUE)[1], ]$Item.ID,
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
      #browser()
      # Pull down just the conditional master item onwards
      # Get current master item id
      currentMaster <- blockMap$Conditional.Master.Item.ID[i]
      masterRow <- which(blockMap$Item.ID == paste0("Item ", currentMaster))[1] # grabbing first just in case
      # Get all items from master onwards
      temp <- blockMap[(masterRow+1):nrow(blockMap),] # We do plus 1 so it doesnt draw to the master (since it draws to first that isnt child)
      flowchart <- rbind(flowchart, data.frame(from = blockMap$Item.ID[i],
                                               to = temp[which(temp$childTrue == FALSE, arr.ind = TRUE)[1],]$Item.ID,
                                               to2 = NA,
                                               parent = FALSE))
    }
  }

  # NOTE here, "to2" is a little silly, but it makes sense and sets up later

  # I think I can just do this, this basically just gets rid of drawing a path to nowhere when the survey is done
  flowchart <- flowchart[!is.na(flowchart$to), ]

  # Some blockmap prep
  # Remove anything that isnt text
  blockMap$Question.Text <- gsub("[^a-zA-Z ]", "", blockMap$Question.Text)
  # If its a block, set Question.Text to "Block"
  blockMap$Question.Text <- ifelse(is.na(blockMap$Question.Text), "Block", blockMap$Question.Text)

  # Change conditional type to the corresponding character rather then numeric
  type_map <- c("=", "<=", ">=", "<", ">", "!=")
  blockMap$Conditional.Type <- type_map[blockMap$Conditional.Type]

  # Map Conditional.Threshold to its corresponding definition in response key. If its a slider or multi slider keep as is
  blockMap$Conditional.Threshold <- mapply(function(threshold, question_id) {
    match_row <- responseKey[
      responseKey$question == question_id &
        responseKey$value == threshold,
    ]

    if (nrow(match_row) > 0 && !match_row$type[1] %in% c("Slider", "Multi Slider")) {
      match_row$definition[1]
    } else {
      threshold
    }
  }, blockMap$Conditional.Threshold, blockMap$Question.ID)

  # Clean so its only text
  blockMap$Conditional.Threshold <- gsub("[^a-zA-Z ]", "", blockMap$Conditional.Threshold)

  wrap_text <- function(text, width = 20) {
    words <- strsplit(text, " ")[[1]]
    lines <- character()
    current_line <- ""

    for (word in words) {
      if (nchar(paste(current_line, word)) <= width) {
        current_line <- trimws(paste(current_line, word))
      } else {
        lines <- c(lines, current_line)
        current_line <- word
      }
    }
    lines <- c(lines, current_line)
    paste(lines, collapse = "<br/>")
  }

  blockMap$Conditional.Threshold <- sapply(blockMap$Conditional.Threshold, wrap_text, width = 20)



  # Build mermaid syntax
  flowchart_syntax <- "graph TD"

  for (i in 1:nrow(flowchart)) {
    current <- flowchart[i,]
    # If parent draw decision node, else just regular path
    if (current$parent) {

      lines <- c(
        # Draw to decision
        paste0(gsub(" ", "_",current$from),"[",blockMap$Question.Text[blockMap$Item.ID == current$from],"] --> ", "decision",i,"{", blockMap$Conditional.Type[blockMap$Item.ID == current$from], " ", blockMap$Conditional.Threshold[blockMap$Item.ID == current$from], "}"),
        # Draw from decision node
        paste0("decision",i,"{", blockMap$Conditional.Type[blockMap$Item.ID == current$from], " ", blockMap$Conditional.Threshold[blockMap$Item.ID == current$from], "} -->|Yes| ", gsub(" ", "_", current$to),"[", blockMap$Question.Text[blockMap$Item.ID == current$to],"]"),
        paste0("decision",i,"{", blockMap$Conditional.Type[blockMap$Item.ID == current$from], " ", blockMap$Conditional.Threshold[blockMap$Item.ID == current$from], "} -->|No| ", gsub(" ", "_", current$to2),"[",blockMap$Question.Text[blockMap$Item.ID == current$to2],"]")
      )

      flowchart_syntax <- paste(
        c(flowchart_syntax, lines),
        collapse = "\n"
      )
    } else {
      lines <- c(paste0(gsub(" ", "_",current$from),"[",blockMap$Question.Text[blockMap$Item.ID == current$from],"] --> ", gsub(" ", "_", current$to), "[",blockMap$Question.Text[blockMap$Item.ID == current$to],"]"))
      flowchart_syntax <- paste(
        c(flowchart_syntax, lines),
        collapse = "\n"
      )
    }
  }


  # Drop duplicated paths
  lines_vec <- strsplit(flowchart_syntax, "\n")[[1]]
  lines_vec <- unique(lines_vec)
  flowchart_syntax <- paste(lines_vec, collapse = "\n")
  #browser()
  # Draw flowchart
  if (shiny) {
    return(flowchart_syntax)
    mermaid(flowchart_syntax)
  } else {
    mermaid(flowchart_syntax)
  }
}

