#' Display Study Metadata
#'
#' This displays key metadata about a study's data collection in a formatted markdown output
#'
#' @param thisData Dataframe containing study data with columns Survey.Date.Completed, Model, and Timezone
#' @return Formatted markdown text displaying data collection period, devices used, and regions/timezones
#' @export


displayStudyMetaData <- function(thisData = thisData) {
  if (nrow(thisData) > 0) {

    dataCollectionPeriod <- range(as.Date(thisData$Survey.Date.Completed), na.rm = TRUE)
    devices <- unique(thisData$Model)[!is.na(unique(thisData$Model))]
    regions <- unique(thisData$Timezone)[!is.na(unique(thisData$Timezone))]

    cat("## Study Metadata\n\n")

    cat("**Data Collection Period:** ", format(dataCollectionPeriod[1], "%B %d, %Y"),
        " to ", format(dataCollectionPeriod[2], "%B %d, %Y"), "\n\n")

    cat("**Devices Used:**\n\n")
    cat(paste("-", devices, collapse = "\n"), "\n\n")

    cat("**Regions / Timezones:**\n\n")
    cat(paste("-", regions, collapse = "\n"), "\n\n")
  }
}
