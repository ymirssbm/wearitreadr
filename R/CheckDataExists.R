#' Check Data Exists
#'
#' This checks if data exists returning a logical, set to 'dataExists' preferred
#'
#' @param id Question or Item ID
#' @param thisData Dataframe containing data
#' @return TRUE or FALSE
#' @export


checkDataExists <- function(id, thisData) {
  if (any(thisData$Question.ID == id) &&
      any(!is.na(thisData$User.Response[thisData$Question.ID == id]))) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

