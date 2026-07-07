#' Frequency Table
#'
#' This generates a simple frequency table for multiple select and multiple choice data
#'
#' @param id Question or Item ID
#' @param thisData Dataframe containing data
#' @param responseKey df containing responseKey
#' @return Frequency table on codebook page
#' @export
#' @importFrom knitr kable
#' @importFrom kableExtra kbl kable_styling column_spec
#' @importFrom dplyr %>%

frequencyTable <- function(id, thisData, responseKey){

  #browser()
  # Check for data
  dataExists <- checkDataExists(id, thisData)

  if(dataExists) {
    # Drop in markdown header
    cat("#### Frequency Table\n\n")

    # This is a simple frequency table
    multiple_select_table <- table(unlist(strsplit(thisData$User.Response[thisData$Question.ID == id], ",")))

    # This gives us the raw counts, ordered for each possible response
    multiple_select_table <- multiple_select_table[order(as.numeric(names(multiple_select_table)))]

    # These are the numeric values in the data
    response_indicator <- names(multiple_select_table)

    # Make each item a character that is N = *insert count*
    n_counts <- sapply(multiple_select_table, function(x) paste0("N = ", x))

    # Next pull out the name labels
    response_labels <- list()

    for (i in seq_along(names(multiple_select_table))) {
      val <- as.numeric(names(multiple_select_table)[i])
      response_labels[[i]] <- responseKey$definition[responseKey$value == val & responseKey$Question.ID == id & !is.na(responseKey$Question.ID) & !is.na(responseKey$definition) & !is.na(responseKey$value)]
    }

    # Unlist
    response_labels <- unlist(response_labels)

    # Grab percentages
    percentages <- round(100 * multiple_select_table / sum(multiple_select_table), 1)

    # Make characters
    percentages <- sapply(percentages, function(x) paste0(x, "%"))



    # Combine all into a dataframe
    df <- data.frame(Value = response_indicator, Label = response_labels, Counts = n_counts, Percentages = percentages)


    # Make table
    html_table <- as.character(
      df %>%
        kbl() %>%
        kable_styling() %>%
        column_spec(3, color = "#006400")
    )
  cat(html_table)

    # If no data, make a table with 0's and labels
  } else {

    response_key_subset <- responseKey[(responseKey$Question.ID == id & responseKey$type == "Response"), ]

    df <- data.frame(
      Value = response_key_subset$value,
      Label = response_key_subset$definition,
      Counts = rep("N = 0", nrow(response_key_subset)),
      Percentages = rep("0%", nrow(response_key_subset))
    )

    # Kable empty table
    html_table <- as.character(
      df %>%
        kbl() %>%
        kable_styling() %>%
        column_spec(3, color = "#006400")
    )
    cat(html_table)
  }
  invisible(NULL)
}
