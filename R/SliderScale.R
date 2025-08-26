#' Silder Hist
#'
#' This function generates a basic histogram for a slider Item or Question
#'
#' @param id Question or Item ID
#' @param thisData Dataframe containing data
#' @return generates basic hist for continuous data
#' @export



sliderHist <- function(id, thisData) {
  dataExists <- checkDataExists(id, thisData)
  # If data exists
  if(dataExists) {

    # Drop in markdown header
    cat("#### Histogram\n\n")
    # Grab data that corresponds to this id
    thisID_df <- thisData[thisData$Question.ID == id,]
    # As numeric the data
    thisID_df$User.Response <- as.numeric(thisID_df$User.Response)

    # Make histogram
    hist(thisID_df$User.Response, main = "Histogram", col ="#619CFF", border = "black", xlab = "0 - 100 Slider", prob = TRUE)

    # This line + prob = TRUE arg draws density plot over histogram
    lines(density(thisID_df$User.Response, na.rm = TRUE), col="blue", lwd=2)
  }
  invisible(NULL)
}


