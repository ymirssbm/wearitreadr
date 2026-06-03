#' Generate Survey Flowchart
#'
#' This generates a Survey Flowchart for a studies WearIT data
#'
#' @param blockMap Blockmap containing data for a single survey
#' @param responseKey wearit responseKey
#' @param survey Full name of survey you want a flowchart for
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


generateSurveyFlowchart <- function(survey, export = FALSE,
                                    blockMap = read.csv("blockMap.csv"),
                                    responseKey = read.csv("responseKey.csv"),
                                    shiny = FALSE, generateText = FALSE) {

  blockMap <- parseBySurvey(blockMap, survey)

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
      if (i < nrow(blockMap)) {
        flowchart <- rbind(flowchart, data.frame(from = blockMap$Item.ID[i],
                                                 to = blockMap$Item.ID[i+1],
                                                 to2 = NA,
                                                 parent = FALSE))
      }
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
      temp <- blockMap[i:nrow(blockMap),]
      next_id <- temp[which(temp$childTrue == FALSE, arr.ind = TRUE)[1],]$Item.ID
      if (length(next_id) > 0 && !is.na(next_id)) {
        flowchart <- rbind(flowchart, data.frame(from = blockMap$Item.ID[i],
                                                 to = next_id,
                                                 to2 = NA,
                                                 parent = FALSE))
      }
    }
  }

  # NOTE here, "to2" is a little silly, but it makes sense and sets up later

  # I think I can just do this, this basically just gets rid of drawing a path to nowhere when the survey is done
  flowchart <- flowchart[!is.na(flowchart$to), ]

  # Some blockmap prep
  # Remove anything that isnt text
  #blockMap$Question.Text <- gsub("[^a-zA-Z ]", "", blockMap$Question.Text)
  # If its a block, set Question.Text to "Block"
  blockMap$Question.Text <- gsub("</?u>", "", blockMap$Question.Text)
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
  blockMap$Conditional.Threshold <- gsub("[^a-zA-Z0-9 ]", "", blockMap$Conditional.Threshold)

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
        paste0(gsub(" ", "_",current$from),'["',blockMap$Question.Text[blockMap$Item.ID == current$from],'"] --> ', "decision",i,"{", blockMap$Conditional.Type[blockMap$Item.ID == current$from], " ", blockMap$Conditional.Threshold[blockMap$Item.ID == current$from], "}"),
        # Draw from decision node
        paste0("decision",i,"{", blockMap$Conditional.Type[blockMap$Item.ID == current$from], " ", blockMap$Conditional.Threshold[blockMap$Item.ID == current$from], "} -->|Yes| ", gsub(" ", "_", current$to),'["', blockMap$Question.Text[blockMap$Item.ID == current$to],'"]'),
        paste0("decision",i,"{", blockMap$Conditional.Type[blockMap$Item.ID == current$from], " ", blockMap$Conditional.Threshold[blockMap$Item.ID == current$from], "} -->|No| ", gsub(" ", "_", current$to2),'["',blockMap$Question.Text[blockMap$Item.ID == current$to2],'"]')
      )
      flowchart_syntax <- paste(
        c(flowchart_syntax, lines),
        collapse = "\n"
      )
    } else {
      lines <- c(paste0(gsub(" ", "_",current$from),'["',blockMap$Question.Text[blockMap$Item.ID == current$from],'"] --> ', gsub(" ", "_", current$to), '["',blockMap$Question.Text[blockMap$Item.ID == current$to],'"]'))
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

  if (generateText) {
    blockMap$Conditional.Threshold <- gsub("<br/>", " ", blockMap$Conditional.Threshold)
    output <- c()
    seen <- c()
    get_label <- function(item_id) {
      label <- blockMap$Question.Text[blockMap$Item.ID == item_id]
      if (length(label) == 0 || is.na(label)) return(item_id)
      return(label[1])
    }
    get_qid <- function(item_id) {
      qid <- blockMap$Question.ID[blockMap$Item.ID == item_id]
      if (length(qid) == 0 || is.na(qid)) return("")
      return(qid[1])
    }
    get_cond <- function(item_id) {
      cond_type   <- blockMap$Conditional.Type[blockMap$Item.ID == item_id]
      cond_thresh <- blockMap$Conditional.Threshold[blockMap$Item.ID == item_id]
      paste0(cond_type[1], " ", cond_thresh[1])
    }
    indent_level <- list()
    for (i in 1:nrow(flowchart)) {
      row <- flowchart[i, ]
      current_indent <- if (!is.null(indent_level[[row$from]])) indent_level[[row$from]] else 0
      pad       <- strrep("  ", current_indent)
      child_pad <- strrep("  ", current_indent + 1)
      # Add FROM node if not seen
      if (!row$from %in% seen) {
        label <- get_label(row$from)
        qid   <- get_qid(row$from)
        if (label != "Block") {
          output <- c(output, paste0(pad, qid, ": ", label))
        }
        seen <- c(seen, row$from)
      }
      # If conditional, show branches with increased indent
      if (row$parent & !is.na(row$to2)) {
        cond      <- get_cond(row$from)
        yes_label <- get_label(row$to)
        no_label  <- get_label(row$to2)
        yes_qid   <- get_qid(row$to)
        no_qid    <- get_qid(row$to2)
        output <- c(output, paste0(pad, "  - IF [", cond, "]:"))
        # If YES points to a block, expand the block's questions inline
        if (yes_label == "Block") {
          block_items <- blockMap[!is.na(blockMap$Block) & blockMap$Block == row$to & blockMap$Item.Type == "Question", ]
          output <- c(output, paste0(child_pad, "  (YES) → Block:"))
          for (j in 1:nrow(block_items)) {
            b_qid   <- block_items$Question.ID[j]
            b_label <- block_items$Question.Text[j]
            output  <- c(output, paste0(child_pad, "    ", b_qid, ": ", b_label))
            seen    <- c(seen, block_items$Item.ID[j])
          }
          indent_level[[row$to]] <- current_indent + 1
        } else {
          output <- c(output, paste0(child_pad, "  ", yes_qid, ": (YES) ", yes_label))
          indent_level[[row$to]] <- current_indent + 1
        }
        output <- c(output, paste0(child_pad, "  ", no_qid, ": (NO)  ", no_label))
        indent_level[[row$to2]] <- current_indent + 1
        seen <- c(seen, row$to, row$to2)
      }
    }
    return(cat(paste(output, collapse = "\n")))
  }

  #browser()
  # Draw flowchart
  if (shiny) {
    return(flowchart_syntax)
  } else if (export) {
    encoded <- openssl::base64_encode(charToRaw(flowchart_syntax))
    encoded <- gsub("\n", "", encoded)
    encoded <- gsub("\\+", "-", encoded)
    encoded <- gsub("/", "_", encoded)
    encoded <- gsub("=", "", encoded)
    url <- paste0("https://mermaid.ink/img/", encoded)
    resp <- httr::GET(url)
    export_file <- file.path(getwd(), paste0(survey, "_flowchart.png"))
    writeBin(httr::content(resp, "raw"), export_file)
    message("Flowchart exported to: ", export_file)
    mermaid(flowchart_syntax)
  } else {
    mermaid(flowchart_syntax)
  }

}
