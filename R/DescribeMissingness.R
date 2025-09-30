#' Desribe Missingness
#'
#' This prints the missingness section for a question or item page
#'
#' @param id Question or Item ID
#' @param thisData Dataframe containing data
#' @param blockMap This is needed for the check skip logic call
#' @return cat msg on codebook page
#' @export
#' @importFrom rmarkdown render
#' @importFrom dplyr filter group_by ungroup
#' @importFrom utils read.csv
#' @importFrom stats sd mean



describeMissingness <- function(id, thisData, blockMap) {

  # Drop in markdown header
  cat("#### Missingness\n\n")

  # Calculate n
  n <- length(unique(thisData$Participant.ID))

  # Grab amount of times question was delivered / delivered and not answered
  # Grab number of times it was answered
  times_delivered <- nrow(thisData[(thisData$Question.ID == id),])

  # Grab number of times it COULD have been answered
  # This is calculated as the amount of times the parent item id was answered with a non NA value
  times_answered <-
    nrow(thisData[(thisData$Question.ID == id & !is.na(thisData$User.Response)),])

  # Grab most basic missingness as times could have been answered
  missing <- times_delivered - times_answered


  # If skip logic exists.....

  skipLogic <- checkSkipLogic(id, blockMap)

  if (skipLogic) {

    ###############
    # 1.) Display the amount of people the question was delivered to
    ###############

    # Grab the amount of people the question was delivered to
    # This is calculated as the amount of people who responded a non NA value to the parent item
    people_delivered_to <-
      length(unique(thisData$Participant.ID[thisData$Question.ID == id & !is.na(thisData$User.Response)]))


    # Make message
    # If the question was delivered to everyone...
    if (n == people_delivered_to) {
      delivered_msg <- paste0("This question/item was delivered to all ", n, " participants")
      cat(delivered_msg)

      # If the question was NOT delivered to everyone...
    } else {
      delivered_msg <- paste0("This question/item was delivered only to ", people_delivered_to, " out of ", n, " participants")
      cat(delivered_msg)
    }


  }


  ###############
  # 3.) Grab missingness descriptives
  ###############

  dataExists <- checkDataExists(id, thisData)

  if (dataExists) {

    # Sum the missingness per person
    missing_per_person <- thisData %>%
      filter(Question.ID == id) %>%
      group_by(Participant.ID) %>%
      summarize(missingness = sum(is.na(User.Response)))



    # Calculate descriptives
    # Minimum
    missing_minimum_value <- round(min(missing_per_person$missingness, na.rm = TRUE), 2)

    # Maximum
    missing_maximum_value <- round(max(missing_per_person$missingness, na.rm = TRUE), 2)

    # Mean
    missing_mean_value <- round(mean(missing_per_person$missingness, na.rm = TRUE), 2)

    # Standard Deviation
    missing_std_value <- round(sd(missing_per_person$missingness, na.rm = TRUE), 2)


    # ICC
    # Between person variance
    between_person_variance <- missing_std_value ^ 2

    # Within person variance
    p_bar <- times_delivered / times_answered
    within_person_variance <- p_bar * (1 - p_bar)
    # Calculate the ICC
    missing_icc_value <- round(between_person_variance / (between_person_variance + within_person_variance), 2)

    # If no data
  } else {
    missing_minimum_value <- NA
    missing_maximum_value <- NA
    missing_mean_value <- NA
    missing_std_value <- NA
    missing_icc_value <- NA
  }

  # Create missingness msg
  msg <- paste0(
    "**Missingness Descriptives**\n\n",
    "Answered / Delivered = ", times_answered, " / ", times_delivered, "\n\n",
    "Missing = ", missing, "\n",
    "Min = ", missing_minimum_value,
    ", Max = ", missing_maximum_value,
    ", Mean = ", missing_mean_value,
    ", SD = ", missing_std_value, "\n",
    "(Descriptives are rounded to 2 decimals)\n\n",
    "Missingness Intraclass Correlation (ICC) = ", missing_icc_value
  )

  # Cat msg
  cat(msg, "\n")

}

