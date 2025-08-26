#' Check Skip Logic
#'
#' This is a simple skip logic check. If skip logic exists, it displays a message on codebook page, if not, ignores.
#' Also returns a flag TRUE or FALSE. Assigning to to 'skipLogic'  preferred
#'
#' @param id Question or item id
#' @param blockMap blockMap, use blockMap_Item if its for by item description
#' @return TRUE or FALSE
#' @export


checkSkipLogic <- function(id, blockMap) {

  # Get current question ID
  item_id_numeric <- substring(id, 6)

  # Change Conditional Child Item ID column to character to make searching easy
  blockMap$Conditional.Child.Item.ID <- as.character(blockMap$Conditional.Child.Item.ID)

  # Check if Item ID is in conditional column....
  ## If so, display parent info
  if (item_id_numeric %in% blockMap$Conditional.Child.Item.ID) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}


#' Display Skip Logic
#'
#' This is a wrapper function on checkSkipLogic that displays a msg if its true, does not return the flag
#'
#' @param id Question or item id
#' @param blockMap blockMap, use blockMap_Item if its for by item description
#' @return Brief cat of msg on codebook page
#' @export

displaySkipLogic <- function(id, blockMap) {

  skipLogic <- checkSkipLogic(id, blockMap)

  if (skipLogic) {

    # Grab just the number
    item_id_numeric <- substring(id, 6)
    # Change Conditional Child Item ID column to character to make searching easy
    blockMap$Conditional.Child.Item.ID <- as.character(blockMap$Conditional.Child.Item.ID)

    parent_row <- subset(blockMap, Conditional.Child.Item.ID == item_id_numeric)
    parent_text <- unique(parent_row$Question.Text)
    parent_itemID <- unique(parent_row$Item.ID)

    # Make message
    msg <- paste0(
      "<div style='font-size:16px; line-height:1.5; margin: 1em 0; padding: 0.5em 1em; ",
      "border-left: 4px solid #2a5caa; background-color: #f9faff; color: #333;'>",
      "<strong>Note:</strong> This question is only delivered if participant answered question ",
      "<em>", parent_itemID, "</em>: <em>", parent_text, "</em>.",
      "</div>"
    )
    #Display message
    cat(msg)
  }

  invisible(NULL)
}
