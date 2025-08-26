#' Slider Descriptives
#'
#' This prints descriptives for a slider item or question type on the codebook page
#'
#' @param id Question or Item ID
#' @param thisData Dataframe containing data
#' @return cat msg on codebook page
#' @export

sliderDescriptives <- function(id, thisData) {

  # Internal function
  dataExists <- checkDataExists(id, thisData)

  # Make sure data exists for it
  if (dataExists) {

    thisID_df <- thisData[thisData$Question.ID == id,]
    thisID_df$User.Response <- as.numeric(thisID_df$User.Response)


    # If data exists grab basic descriptives
    minimum_value <- round(min(thisID_df$User.Response, na.rm = TRUE), 2)
    maximum_value <- round(max(thisID_df$User.Response, na.rm = TRUE), 2)
    mean_value <- round(mean(thisID_df$User.Response, na.rm = TRUE), 2)
    std_value <- round(sd(thisID_df$User.Response, na.rm = TRUE), 2)

  } else {

    # If no data set NA values
    minimum_value <- NA
    maximum_value <- NA
    mean_value <- NA
    std_value <- NA
  }

  # Create descriptives message
  msg <- paste0(
    "**Descriptives**\n",
    "Min = ", minimum_value, ", ",
    "Max = ", maximum_value, ", ",
    "Mean = ", mean_value, ", ",
    "SD = ", std_value
  )

  # Cat msg
  cat(msg, "\n")
  invisible(NULL)
}
