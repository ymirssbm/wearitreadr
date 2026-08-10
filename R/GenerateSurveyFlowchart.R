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
  allChildIDs <- unlist(lapply(blockMap$Conditional.Child.Item.ID, splitList))

  for (i in 1:nrow(blockMap)) {
    if (blockMap$Item.Type[i] == "Block") {
      blockMap$childTrue[i] <- FALSE
    } else {
      if (substring(blockMap$Item.ID[i], 6) %in% allChildIDs) {
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
  flowchart <- data.frame()



  # Logic structure

  # If block, draw block and draw down (this works because the blocks are sorted and placed at the top of their sections)

  # If question, do these 3 checks

  # 1.) If its not a parent, draw to the next thing thats not a child (unless it has an exit row, then draw to the exit row)
  # 2.) If its a parent AT all, regardless of child status, draw to each child (mark its a parent so I can draw conditional step)

  for (i in 1:nrow(blockMap)) {

    # 1.)
    if (blockMap$parentTrue[i] == FALSE) {
      if (!is.na(blockMap$Exit.Row[i])) {
        flowchart <- dplyr::bind_rows(flowchart, data.frame(from = blockMap$Item.ID[i],
                                                            to1 = blockMap$Exit.Row[i],
                                                            parent = FALSE))
      } else {
        if (i < nrow(blockMap)) {
          temp <- blockMap[(i + 1):nrow(blockMap), ]
          next_id <- temp$Item.ID[which(temp$childTrue == FALSE)[1]]
        } else {
          next_id <- NA
        }
        if (length(next_id) > 0 && !is.na(next_id)) {
          flowchart <- dplyr::bind_rows(flowchart, data.frame(from = blockMap$Item.ID[i],
                                                              to1 = next_id,
                                                              parent = FALSE))
        }
      }
    }
    # 2.)
    if (blockMap$parentTrue[i] == TRUE) {
      to_list <- list()
      numChildren <- length(splitList(blockMap$Conditional.Child.Item.ID[i]))
      # Draw a path for each child
      if (numChildren > 0) {
        for (j in 1:numChildren) {
          to_list[[j]] <- paste0("Item ", splitList(blockMap$Conditional.Child.Item.ID[i]))[j]
        }
        names(to_list) <- paste0("to", 1:numChildren)
      }
      flowchart <- dplyr::bind_rows(flowchart, data.frame(from = blockMap$Item.ID[i],
                                                          to_list,
                                                          fail = paste0("Item ", blockMap$Conditional.Fail.Item.ID[i]),
                                                          parent = TRUE))
    }
  }



  # NOTE here, "to2" is a little silly, but it makes sense and sets up later

  # I think I can just do this, this basically just gets rid of drawing a path to nowhere when the survey is done
  to_cols <- grep("^to[0-9]*$", names(flowchart), value = TRUE)
  has_dest <- apply(flowchart[, to_cols, drop = FALSE], 1, function(r) any(!is.na(r)))
  flowchart <- flowchart[has_dest, ]



  # Some blockmap prep
  # Remove anything that isnt text
  #blockMap$Question.Text <- gsub("[^a-zA-Z ]", "", blockMap$Question.Text)
  # If its a block, set Question.Text to "Block"
  blockMap$Question.Text <- gsub("</?u>", "", blockMap$Question.Text)
  blockMap$Question.Text <- ifelse(is.na(blockMap$Question.Text), "Block", blockMap$Question.Text)

  # Change conditional type to the corresponding character rather then numeric
  type_map <- c("=", "<=", ">=", "<", ">", "!=")
  blockMap$Conditional.Type <- type_map[blockMap$Conditional.Type]

  # Map Conditional.Threshold to its corresponding definition in response key (single-value conditionals)
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

  # Convert to a list-column so multi-conditional rows can carry MULTIPLE grouped labels
  # (one per path) instead of one flat string
  blockMap$Conditional.Threshold <- as.list(blockMap$Conditional.Threshold)

  # For multi-conditional rows: Definitions is "group1; group2; ..." where each semicolon-
  # separated group is the full set of values that route down ONE path. Split on ";" only --
  # splitList() (comma split) would destroy the group boundaries.
  multi_idx <- which(blockMap$Multi.Conditional == TRUE)
  blockMap$Conditional.Threshold[multi_idx] <- lapply(
    blockMap$Definitions[multi_idx],
    function(x) trimws(strsplit(x, ";")[[1]])
  )

  # Clean + wrap. Multi-conditional entries are a vector (one element per path/group);
  # everything else stays a single string, wrapped as before.
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

  blockMap$Conditional.Threshold <- lapply(blockMap$Conditional.Threshold, function(vals) {
    if (all(is.na(vals))) return(vals)
    vals <- gsub("[^a-zA-Z0-9 ]", "", vals)
    vapply(vals, wrap_text, character(1), width = 20, USE.NAMES = FALSE)
  })

  #browser()

  # Build mermaid syntax
  flowchart_syntax <- "graph TD"

  for (i in 1:nrow(flowchart)) {
    current <- flowchart[i,]

    if (current$parent) {
      is_multi <- isTRUE(blockMap$Multi.Conditional[blockMap$Item.ID == current$from][1])
      thresh   <- blockMap$Conditional.Threshold[blockMap$Item.ID == current$from][[1]]

      if (is_multi) {
        # Already one label-group per path, in child order -- don't re-split
        thresh <- as.character(thresh)
      } else {
        # Single string; multiple children map to comma-separated values within it
        thresh <- strsplit(thresh, ", ")[[1]]
      }

      decision_label <- paste0("decision", i, "{ }")

      lines <- c(
        paste0(gsub(" ", "_", current$from), '["', blockMap$Question.Text[blockMap$Item.ID == current$from], '"] --> ', decision_label)
      )

      to_cols <- grep("^to[0-9]*$", names(current), value = TRUE)
      for (col in to_cols) {
        to_val <- current[[col]]
        if (!is.na(to_val)) {
          j <- as.integer(gsub("to", "", col))
          edge_label <- if (!is.na(thresh[j]) && nzchar(thresh[j])) thresh[j] else "Other"
          lines <- c(lines,
                     paste0(decision_label, " -->|", edge_label, "| ", gsub(" ", "_", to_val), '["', blockMap$Question.Text[blockMap$Item.ID == to_val], '"]')
          )
        }
      }

      if ("fail" %in% names(current) && !is.na(current$fail)) {
        lines <- c(lines,
                   paste0(decision_label, " -->|Fail| ", gsub(" ", "_", current$fail), '["', blockMap$Question.Text[blockMap$Item.ID == current$fail], '"]')
        )
      }

      flowchart_syntax <- paste(c(flowchart_syntax, lines), collapse = "\n")
    } else {
      lines <- c(paste0(gsub(" ", "_", current$from), '["', blockMap$Question.Text[blockMap$Item.ID == current$from], '"] --> ', gsub(" ", "_", current$to1), '["', blockMap$Question.Text[blockMap$Item.ID == current$to1], '"]'))
      flowchart_syntax <- paste(c(flowchart_syntax, lines), collapse = "\n")
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
