#' screenshots
#'
#' This generates yaml file for maestro to grab wear it screenshots
#'
#' @param blockMap Blockmap containing data for a single survey
#' @param responseKey wearit responseKey
#' @param survey Full name of survey you want a flowchart for
#' @param shiny boolean indicating whether using shiny app
#' @return NULL
#' @importFrom utils read.csv
#' @export

getSurveyScreenshots <- function(survey,
                                 blockMap = read.csv("blockMap.csv"),
                                 responseKey = read.csv("responseKey.csv"),
                                 shiny = FALSE) {

  blockMap <- parseBySurvey(blockMap, survey)
  blockMap <- blockMap[!is.na(blockMap$Question.Type.Display.Name), ]

  header <- "appId: com.your.app.package\n---\n"
  body   <- walkBlockMap(blockMap, responseKey)

  # every piece already ends in "\n", so collapse with no separator
  fullYaml <- paste0(header, paste0(body, collapse = ""))

  if (!shiny) {
    cat(fullYaml)
  }

  writeLines(fullYaml, "output.yaml", sep = "")

  invisible(fullYaml)
}

##################
# Helper functions
##################

walkBlockMap <- function(blockMap, responseKey) {

  yaml <- c()
  i <- 1
  n <- nrow(blockMap)

  while (i <= n) {
    row <- blockMap[i, ]

    # "End Block" is a bookkeeping marker only, not a real screen shown to
    # the user -- no screenshot, no tap, no advance. Just skip past it.
    if (identical(row$Question.Type.Display.Name, "End Block")) {
      i <- i + 1
      next
    }

    # every real question gets screenshotted, regardless of conditional type
    yaml <- c(yaml, takeScreenshot(row))

    if (isTRUE(row$Multi.Conditional)) {
      childIDs <- paste0("Item ", trimws(strsplit(row$Conditional.Child.Item.ID, ";")[[1]]))
      descendantRows <- which(!is.na(blockMap$Block) & blockMap$Block %in% childIDs)

      yaml <- c(yaml, selectComplexConditional(row, blockMap, childIDs, descendantRows, responseKey))

      exitID  <- blockMap$Exit.Row[descendantRows][!is.na(blockMap$Exit.Row[descendantRows])][1]
      exitIdx <- which(blockMap$Item.ID == exitID)
      stopifnot(length(exitIdx) == 1)

      i <- exitIdx
      next
    }

    if (!is.na(row$Conditional.Type)) {
      yaml <- c(yaml, selectSimpleConditional(row, responseKey))
    } else {
      yaml <- c(yaml, skipQuestion(row))
    }

    i <- i + 1
  }

  yaml
}

swipeText <- function() {
  paste0(
    '- swipe:\n',
    '    start: 50%, 85%\n',
    '    end: 50%, 55%\n',
    '    duration: 400\n'
  )
}

swipeToTopText <- function() {
  paste0(
    '- swipe:\n',
    '    start: 50%, 55%\n',
    '    end: 50%, 85%\n',
    '    duration: 400\n'
  )
}

needsSwipe <- function(type) {
  type %in% c("Multiple Slider", "Multiple Select", "Multiple Choice")
}

takeScreenshot <- function(row) {
  type <- row$Question.Type.Display.Name
  id   <- row$Item.ID

  screenshotText <- paste0('- takeScreenshot: "', id, '"\n')

  if (needsSwipe(type)) {
    screenshotText <- c(screenshotText,
                        swipeText(),
                        paste0('- takeScreenshot: "', id, '_2"\n'),
                        swipeToTopText()
    )
  }

  screenshotText
}

skipQuestion <- function(row) {
  type <- row$Question.Type.Display.Name

  if (type %in% "Informational Fullscreen") {
    skipText <- paste0(
      '- tapOn: "Right-facing arrow indicating next question"\n',
      '- waitForAnimationToEnd\n'
    )
  } else {
    skipText <- paste0(
      '- tapOn: "Right-facing arrow indicating next question"\n',
      '- waitForAnimationToEnd\n',
      '- tapOn: "OK"\n',
      '- waitForAnimationToEnd\n'
    )
  }

  skipText
}

selectSimpleConditional <- function(row, responseKey) {

  comparator <- switch(as.character(row$Conditional.Type),
                       "1" = "=", "2" = "<=", "3" = ">=",
                       "4" = "<", "5" = ">", "6" = "!="
  )

  threshold <- row$Conditional.Threshold
  qid <- row$Question.ID

  matches <- switch(comparator,
                    "="  = responseKey[responseKey$question == qid & responseKey$value == threshold, ],
                    "<=" = responseKey[responseKey$question == qid & responseKey$value <= threshold, ],
                    ">=" = responseKey[responseKey$question == qid & responseKey$value >= threshold, ],
                    "<"  = responseKey[responseKey$question == qid & responseKey$value < threshold, ],
                    ">"  = responseKey[responseKey$question == qid & responseKey$value > threshold, ],
                    "!=" = responseKey[responseKey$question == qid & responseKey$value != threshold, ]
  )

  definition <- matches$definition[1]

  paste0(
    scrollUntilVisibleLoop(definition),
    '- tapOn: "', definition, '"\n',
    '- tapOn: "Right-facing arrow indicating next question"\n',
    '- waitForAnimationToEnd\n'
  )
}

selectComplexConditional <- function(row, blockMap, childIDs, descendantRows, responseKey) {

  defGroups <- trimws(strsplit(row$Definitions, ";")[[1]])
  stopifnot(length(defGroups) == length(childIDs))

  yaml <- c()

  for (b in seq_along(defGroups)) {
    firstOption <- trimws(strsplit(defGroups[b], "\\|")[[1]][1])

    yaml <- c(yaml,
              scrollUntilVisibleLoop(firstOption),
              paste0('- tapOn: "', firstOption, '"\n'),
              '- tapOn: "Right-facing arrow indicating next question"\n',
              '- waitForAnimationToEnd\n'
    )

    childBlock <- blockMap[!is.na(blockMap$Block) & blockMap$Block == childIDs[b], ]
    yaml <- c(yaml, walkBlockMap(childBlock, responseKey))

    if (b < length(defGroups)) {
      nBackSteps <- nrow(childBlock) + 1
      yaml <- c(yaml, rep('- back\n- waitForAnimationToEnd\n', nBackSteps))
      yaml <- c(yaml,
                scrollUntilVisibleLoop(firstOption),
                paste0('- tapOn: "', firstOption, '"\n')  # deselect
      )
    }
  }

  yaml
}


scrollUntilVisibleLoop <- function(target, direction = "DOWN") {
  swipeCmd <- if (direction == "DOWN") {
    paste0(
      '    - swipe:\n',
      '        start: 50%, 85%\n',
      '        end: 50%, 55%\n',
      '        duration: 400\n'
    )
  } else {
    paste0(
      '    - swipe:\n',
      '        start: 50%, 55%\n',
      '        end: 50%, 85%\n',
      '        duration: 400\n'
    )
  }

  paste0(
    '- repeat:\n',
    '    while:\n',
    '      notVisible:\n',
    '        text: "', target, '"\n',
    '    commands:\n',
    swipeCmd
  )
}
