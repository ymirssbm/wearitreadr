#' Pull study schedule
#'
#' This pulls burst and survey schedule info from a study URL and returns a flattened data frame
#'
#' @param url URL pointing to the study schedule JSON
#' @return data frame containing burst and survey schedule info
#' @importFrom jsonlite fromJSON
#' @export

studySchedulePull <- function(url) {

  df <- fromJSON(url, simplifyVector = F, flatten = T)

  # Loop over each burst
  results <- lapply(df, function(burst) {
    # Loop over each survey
    survey_rows <- lapply(burst$bss, function(survey) {
      data.frame(
        Burst.ID = burst$order,
        Survey.Name = survey$survey$surveyTitle,
        Survey.Description = survey$survey$surveyDescription,
        Days.On = survey$days_on,
        Days.Off = survey$days_off,
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, survey_rows)
  })
  studySchedule <- do.call(rbind, results)
  return(studySchedule)
}

