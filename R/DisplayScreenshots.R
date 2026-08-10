#' Display Screenshot
#'
#' Embeds the Maestro-generated screenshot(s) for a given item into the codebook.
#' Looks for "<id>.png" and, if present, "<id>_2.png" (for question types that
#' produce two screenshots), matching the naming convention from takeScreenshot().
#'
#' @param id Item.ID value from blockMap (e.g. "Item 5734")
#' @param screenshotDir Directory containing the .png files output by the Maestro run
#' @return NULL invisibly; cats HTML image tags as a side effect
#' @export
displayScreenshot <- function(id, screenshotDir = "screenshots") {

  primaryFile   <- file.path(screenshotDir, paste0(id, ".png"))
  secondaryFile <- file.path(screenshotDir, paste0(id, "_2.png"))

  filesToShow <- c(primaryFile, secondaryFile)
  filesToShow <- filesToShow[file.exists(filesToShow)]

  if (length(filesToShow) == 0) {
    cat("\n\n*No screenshot available for this item.*\n\n")
    return(invisible(NULL))
  }

  for (f in filesToShow) {
    cat(paste0(
      '\n\n<img src="', f, '" style="max-width:300px; border:1px solid #ccc; margin:5px;">\n\n'
    ))
  }

  invisible(NULL)
}
