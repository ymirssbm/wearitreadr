#' Complex conditional
#'
#' This pulls multi conditional info and joins with blockMap
#'
#' @param blockMap Blockmap containing data for a single survey
#' @param responseKey wearit responseKey
#' @param survey Full name of survey you want a flowchart for
#' @param shiny boolean indicating whether using shiny app
#' @return updated blockMap
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr left_join mutate select relocate na_if coalesce bind_rows
#' @importFrom magrittr %>%
#' @export

complexConditional <- function(url="https://wearables.vmhost.psu.edu/wearables-survey/Survey/blockStructure?s_id=75&g_id=1045", blockMap) {

  df <- fromJSON(url, simplifyVector = F, flatten = T)

  all_results <- lapply(df[[1]][["bsss"]], function(x) {
    item_rows <- lapply(x[["survey"]][["surveyDataItems"]], function(item) {
      # If block, check each item inside it independently
      if(item$type == 'block') {
        blockRows <- lapply(item[["blockItems"]], function(blockItem) {
          # Check if its a special conditional
          if (blockItem$conditionalLimit != 0) {
            multiConditional <- TRUE
            Question.ID <- blockItem$sQuId
            conditionalLimit <- blockItem$conditionalLimit
            # Loop over each response
            definitions <- sapply(blockItem[["responses"]], function(response) response$rTx)
            conditionalChildIds <- sapply(blockItem[["responses"]], function(response) response$conditionalChild)
            # Group definitions by which question they branch to
            grouped <- split(definitions, factor(conditionalChildIds, levels = unique(conditionalChildIds)))
            # Return dataframe
            return(data.frame(
              Question.ID = paste0("Question ", Question.ID),
              Multi.Conditional = multiConditional,
              Conditional.Limit = conditionalLimit,
              Conditional.Child.Item.ID = paste(names(grouped), collapse = "; "),
              Definitions = paste(sapply(grouped, paste, collapse = ", "), collapse = "; ")
            ))
          }
        })
        return(bind_rows(blockRows))
      }
      # If conditional exists...
      if (item$conditionalLimit != 0) {
        conditionalLimit <- item$conditionalLimit
        # If Question just grab once
        if(item$type == 'question') {
          multiConditional <- TRUE
          Question.ID <- item$sQuId
          # Loop over each response
          definitions <- sapply(item[["responses"]], function(response) response$rTx)
          conditionalChildIds <- sapply(item[["responses"]], function(response) response$conditionalChild)
          # Group definitions by which question they branch to
          grouped <- split(definitions, factor(conditionalChildIds, levels = unique(conditionalChildIds)))
          # Return dataframe
          return(data.frame(
            Question.ID = paste0("Question ", Question.ID),
            Multi.Conditional = multiConditional,
            Conditional.Limit = conditionalLimit,
            Conditional.Child.Item.ID = paste(names(grouped), collapse = "; "),
            Definitions = paste(sapply(grouped, paste, collapse = "|"), collapse = "; ")
          ))
        }
      }
    })
    # Combine all items together
    bind_rows(item_rows)
  })
  # Combine at top level
  conditional_df <- bind_rows(all_results)


  # Join complex conditionals with regular block map
  blockMap <- blockMap %>%
    left_join(conditional_df, by = "Question.ID") %>%
    mutate(
      Conditional.Child.Item.ID.x = as.character(Conditional.Child.Item.ID.x),
      Conditional.Child.Item.ID.y = as.character(Conditional.Child.Item.ID.y),
      Conditional.Child.Item.ID.x = dplyr::na_if(Conditional.Child.Item.ID.x, ""),
      Conditional.Child.Item.ID.y = dplyr::na_if(Conditional.Child.Item.ID.y, ""),
      Conditional.Child.Item.ID = dplyr::coalesce(Conditional.Child.Item.ID.x, Conditional.Child.Item.ID.y)
    ) %>%
    select(-Conditional.Child.Item.ID.x, -Conditional.Child.Item.ID.y) %>%
    relocate(Conditional.Child.Item.ID, .after = Question.Type)

  blockMap$Conditional.Type[which(blockMap$Multi.Conditional)] <- "1"

  # This helps assess the span of a branch to see where blocks inside the branch that are mutually exclusive exit to
  spanEnd <- function(itemID, blockMap) {
    startIdx <- which(blockMap$Item.ID == itemID)
    if (length(startIdx) == 0) {
      warning("spanEnd: itemID not found in blockMap: ", itemID)
      return(NA_integer_)
    }

    stack <- c(itemID)
    visited <- character(0)
    maxIdx <- startIdx
    while (length(stack) > 0) {
      current <- stack[1]
      stack <- stack[-1]
      if (current %in% visited) next
      visited <- c(visited, current)

      idx <- which(blockMap$Item.ID == current)
      if (length(idx) == 0) next
      maxIdx <- max(maxIdx, idx)

      members <- blockMap$Item.ID[blockMap$Block == current]
      stack <- c(stack, setdiff(members, visited))
    }
    maxIdx
  }

  # Using span end to identify Exit.Row for the end of blocks

  blockMap$Exit.Row <- NA  # initialize new column first

  for (i in 1:nrow(blockMap)) {
    if (isTRUE(blockMap$Multi.Conditional[i])) {

      children <- splitList(blockMap$Conditional.Child.Item.ID[i])
      if (length(children) == 0) next

      childFullIDs <- unique(paste0("Item ", children))
      endIdxs <- sapply(childFullIDs, spanEnd, blockMap = blockMap)

      overallMaxIdx <- max(endIdxs, na.rm = TRUE)
      exitIdx <- overallMaxIdx + 1
      exitItemID <- if (exitIdx <= nrow(blockMap)) blockMap$Item.ID[exitIdx] else NA

      # Conditional.Fail.Item.ID stores just the bare number, no "Item " prefix
      blockMap$Conditional.Fail.Item.ID[i] <- sub("^Item ", "", exitItemID)

      # Exit.Row gets set on the tail (max row) of EVERY branch, not just the longest one
      for (endIdx in endIdxs) {
        if (!is.na(endIdx)) {
          blockMap$Exit.Row[endIdx] <- exitItemID
        }
      }
    }
  }
  return(blockMap)
}

