#' parentChild
#'
#' This makes 2 new boolean columns in blockMap, parent and child.
#' If the block or question is a parent, TRUE it, otherwise FALSE. Same for child. This does not check for parent or child of survey.
#'
#' @param blockMap dataframe containing blockMap
#' @return TRUE or FALSE cols in blockMap
#' @export

parentChild <- function(blockMap) {

  newCols <- c("parentTrue", "childTrue")
  blockMap[,newCols] <- NA

  # For each row in blockMap
  for (i in 1:nrow(blockMap)) {
    # Set parentTrue
    if (blockMap$Item.ID[i] %in% blockMap$Parent) {
      blockMap$parentTrue[i] <- TRUE
    } else {
      blockMap$parentTrue[i] <- FALSE
    }

    # Set childTrue
    if (blockMap$Parent[i] %in% blockMap$Item.ID) {
      blockMap$childTrue[i] <- TRUE
    } else {
      blockMap$childTrue[i] <- FALSE
    }
  }
}
