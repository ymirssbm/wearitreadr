#' Generate Survey Tree
#'
#' This generates a Survey Tree for a study's WearIT data using DiagrammeR/Mermaid
#'
#' @param blockMapParsed Blockmap containing data for a single survey
#' @param shiny boolean indicating whether using shiny app
#' @param showLabels boolean indicating whether to show node labels
#' @return survey tree rendered as a Mermaid flowchart
#' @import DiagrammeR
#' @importFrom utils read.csv
#' @export
generateSurveyTree <- function(shiny = FALSE, blockMapParsed, showLabels = TRUE) {
  blockMap <- blockMapParsed

  # Initialize node levels to track position of nodes
  nodeLevels <- setNames(rep(NA, nrow(blockMap)), blockMap$Item.ID)
  currentLevel <- 0

  # Create boolean col for child status
  blockMap$childTrue <- substring(blockMap$Item.ID, 6) %in% blockMap$Conditional.Child.Item.ID

  # --- Build edge list by walking the blockmap ---
  edges <- data.frame(from = character(), to = character(), label = character(), stringsAsFactors = FALSE)

  for (i in 1:nrow(blockMap)) {
    if (blockMap$childTrue[i]) next

    item <- blockMap[i, ]

    # Assign level to this node if not yet set
    if (is.na(nodeLevels[item$Item.ID])) {
      nodeLevels[item$Item.ID] <- currentLevel
      currentLevel <- currentLevel + 1
    }

    has_child   <- !is.na(item$Conditional.Child.Item.ID)
    has_fail    <- !is.na(item$Conditional.Fail.Item.ID)
    is_decision <- has_child | has_fail

    # Sequential edge to next non-child item — only for non-decision nodes
    if (i < nrow(blockMap) && !is_decision) {
      lowerRows <- blockMap[(i + 1):nrow(blockMap), , drop = FALSE]
      lowerRows <- lowerRows[!is.na(lowerRows$childTrue) & lowerRows$childTrue == FALSE, , drop = FALSE]
      if (nrow(lowerRows) > 0 && !is.na(lowerRows$Item.ID[1])) {
        edges <- rbind(edges, data.frame(
          from  = item$Item.ID,
          to    = lowerRows$Item.ID[1],
          label = "",
          stringsAsFactors = FALSE
        ))
      }
    }

    if (is_decision) {
      parentLevel <- nodeLevels[item$Item.ID]

      # Yes branch
      if (has_child) {
        childID <- paste0("Item ", item$Conditional.Child.Item.ID)
        edges <- rbind(edges, data.frame(from = item$Item.ID, to = childID, label = "Yes", stringsAsFactors = FALSE))
        if (is.na(nodeLevels[childID])) nodeLevels[childID] <- parentLevel + 0.5
      }

      # No branch
      if (has_fail) {
        failID <- paste0("Item ", item$Conditional.Fail.Item.ID)
        edges <- rbind(edges, data.frame(from = item$Item.ID, to = failID, label = "No", stringsAsFactors = FALSE))
        if (is.na(nodeLevels[failID])) nodeLevels[failID] <- parentLevel + 0.5
      }

      # Walk the conditional chain
      if (has_child) {
        child <- blockMap[blockMap$Item.ID == paste0("Item ", item$Conditional.Child.Item.ID), , drop = FALSE]

        while (nrow(child) > 0 &&
               (!is.na(child$Conditional.Child.Item.ID) | !is.na(child$Conditional.Fail.Item.ID))) {

          childParentLevel <- nodeLevels[child$Item.ID]

          if (!is.na(child$Conditional.Child.Item.ID)) {
            nestedChildID <- paste0("Item ", child$Conditional.Child.Item.ID)
            edges <- rbind(edges, data.frame(from = child$Item.ID, to = nestedChildID, label = "Yes", stringsAsFactors = FALSE))
            if (is.na(nodeLevels[nestedChildID])) nodeLevels[nestedChildID] <- childParentLevel + 0.5
          }

          if (!is.na(child$Conditional.Fail.Item.ID)) {
            nestedFailID <- paste0("Item ", child$Conditional.Fail.Item.ID)
            edges <- rbind(edges, data.frame(from = child$Item.ID, to = nestedFailID, label = "No", stringsAsFactors = FALSE))
            if (is.na(nodeLevels[nestedFailID])) nodeLevels[nestedFailID] <- childParentLevel + 0.5
          }

          if (!is.na(child$Conditional.Child.Item.ID)) {
            child <- blockMap[blockMap$Item.ID == paste0("Item ", child$Conditional.Child.Item.ID), , drop = FALSE]
          } else {
            break
          }
        }
      }

      # After the conditional chain resolves, draw edge from decision node
      # to the next non-child item in the main sequence
      if (i < nrow(blockMap)) {
        lowerRows <- blockMap[(i + 1):nrow(blockMap), , drop = FALSE]
        lowerRows <- lowerRows[!is.na(lowerRows$childTrue) & lowerRows$childTrue == FALSE, , drop = FALSE]
        if (nrow(lowerRows) > 0 && !is.na(lowerRows$Item.ID[1])) {
          nextMainID <- lowerRows$Item.ID[1]
          # Only draw if not already a Yes/No target
          already_targeted <- nextMainID %in% c(
            if (has_child) paste0("Item ", item$Conditional.Child.Item.ID) else character(0),
            if (has_fail)  paste0("Item ", item$Conditional.Fail.Item.ID)  else character(0)
          )
          if (!already_targeted) {
            edges <- rbind(edges, data.frame(
              from  = item$Item.ID,
              to    = nextMainID,
              label = "Continue",
              stringsAsFactors = FALSE
            ))
          }
        }
      }
    }
  }

  edges <- unique(edges)
  edges <- edges[!is.na(edges$to), ]

  # --- Helpers ---
  sanitize_id <- function(x) gsub("[^A-Za-z0-9_]", "_", trimws(x))

  # Determine which Item IDs are decision nodes
  decision_ids <- blockMap$Item.ID[
    !is.na(blockMap$Conditional.Child.Item.ID) | !is.na(blockMap$Conditional.Fail.Item.ID)
  ]

  # First and last non-child items are terminals
  non_child_ids <- blockMap$Item.ID[!blockMap$childTrue]
  start_id <- non_child_ids[1]
  end_id   <- non_child_ids[length(non_child_ids)]

  # --- Build Mermaid node definitions ---
  # Shape key:
  #   Terminal (start/end) : ([label])  — stadium / rounded pill
  #   Decision             : {label}    — diamond
  #   Conditional child    : [/label/]  — parallelogram
  #   Standard process     : [label]    — rectangle
  node_lines <- vapply(seq_len(nrow(blockMap)), function(i) {
    raw_id <- blockMap$Item.ID[i]
    id     <- sanitize_id(raw_id)
    label  <- if (showLabels) raw_id else " "

    is_terminal   <- raw_id %in% c(start_id, end_id)
    is_decision   <- raw_id %in% decision_ids
    is_cond_child <- blockMap$childTrue[i]

    if (is_terminal) {
      sprintf('  %s(["%s"])', id, label)
    } else if (is_decision) {
      sprintf('  %s{"%s"}', id, label)
    } else if (is_cond_child) {
      sprintf('  %s[/"%s"/]', id, label)
    } else {
      sprintf('  %s["%s"]', id, label)
    }
  }, character(1))

  # --- Build Mermaid edge definitions ---
  edge_lines <- vapply(seq_len(nrow(edges)), function(i) {
    from <- sanitize_id(edges$from[i])
    to   <- sanitize_id(edges$to[i])
    lbl  <- edges$label[i]
    if (nzchar(lbl)) {
      sprintf("  %s -->|%s| %s", from, lbl, to)
    } else {
      sprintf("  %s --> %s", from, to)
    }
  }, character(1))

  # --- Assemble Mermaid diagram string ---
  mermaid_code <- paste(
    c(
      "graph LR",
      node_lines,
      edge_lines
    ),
    collapse = "\n"
  )

  if (shiny) {
    return(mermaid_code)
  } else {
    DiagrammeR::mermaid(mermaid_code)
  }
}
