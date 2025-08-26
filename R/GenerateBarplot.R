#' Generate Barplot
#'
#' Generates a simple bar plot for a given quesiton or item
#'
#'@param id Question or Item id
#'@param thisData df containing data
#'@param questionText Question or Item's corresponding text squiggly brackets insertion preferred
#'@return ggplot table
#'@export
#'@importFrom ggplot2 ggplot geom_bar labs theme_minimal aes

generateBarplot <- function() {

  # Check to make sure the last call made a table
  dataExists <- checkDataExists(id, thisData, questionText)

  if (dataExists) {

    # Drop in markdown header
    cat("#### Barplot\n\n")

    # This is a simple frequency table
    multiple_select_table <- table(unlist(strsplit(thisData$User.Response[thisData$Question.ID == id], ",")))

    # This gives us the raw counts, ordered for each possible response
    multiple_select_table <- multiple_select_table[order(as.numeric(names(multiple_select_table)))]

    # Convert to data frame dynamically
    df <- data.frame(
      Option = factor(names(multiple_select_table), levels = names(multiple_select_table)),
      Count = as.numeric(multiple_select_table)
    )

    # Create ggplot
    ggplot(df, aes(x = Option, y = Count)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      labs(
        title = questionText,
        x = "",
        y = ""
      ) +
      theme_minimal()
  }
}
