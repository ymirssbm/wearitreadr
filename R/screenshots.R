#' Generate Survey Flowchart
#'
#' This generates a Survey Flowchart for a studies WearIT data
#'
#' @param blockMap Blockmap containing data for a single survey
#' @param responseKey wearit responseKey
#' @param survey Full name of survey you want a flowchart for
#' @param shiny boolean indicating whether using shiny app
#' @return NULL
#' @importFrom utils read.csv
#' @export

screenshots <- function(survey,
                        blockMap = read.csv("blockMap.csv"),
                        responseKey = read.csv("responseKey.csv"),
                        shiny = FALSE) {

  blockMap <- parseBySurvey(blockMap, survey)
  blockMap <- blockMap[!is.na(blockMap$Question.Type.Display.Name), ]

  yamlLines <- c("appId: com.your.app.package\n---")

  for (i in 1:nrow(blockMap)) {
    type <- blockMap$Question.Type.Display.Name[i]
    id <- blockMap$Item.ID[i]

    yamlCommand <- switch(type,
                          "Multiple Select" = {
                            if (is.na(blockMap$Conditional.Type[i])) {
                              paste0(
                                '- takeScreenshot: "', id, '"\n',
                                '- swipe:\n',
                                '    start: 50%, 85%\n',
                                '    end: 50%, 55%\n',
                                '    duration: 400\n',
                                '- takeScreenshot: "', id, '_2"\n',
                                '- tapOn: "Right-facing arrow indicating next question"\n',
                                '- waitForAnimationToEnd\n',
                                '- tapOn: "OK"\n',
                                '- waitForAnimationToEnd'
                              )
                            } else {

                              comparator <- switch(as.character(blockMap$Conditional.Type[i]),
                                                   "1" = "=", "2" = "<=", "3" = ">=",
                                                   "4" = "<", "5" = ">", "6" = "!="
                              )

                              threshold <- blockMap$Conditional.Threshold[i]
                              qid <- blockMap$Question.ID[i]

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
                                '- takeScreenshot: "', id, '"\n',
                                '- swipe:\n',
                                '    start: 50%, 85%\n',
                                '    end: 50%, 55%\n',
                                '    duration: 400\n',
                                '- takeScreenshot: "', id, '_2"\n',
                                '- tapOn: "', definition, '"\n',
                                '- waitForAnimationToEnd\n',
                                '- tapOn: "Right-facing arrow indicating next question"\n',
                                '- waitForAnimationToEnd'
                              )
                            }
                          },
                          "Free Response" = {
                            paste0(
                              '- takeScreenshot: "', id, '"\n',
                              '- tapOn: "Right-facing arrow indicating next question"\n',
                              '- waitForAnimationToEnd\n',
                              '- tapOn: "OK"\n',
                              '- waitForAnimationToEnd'
                            )
                          },
                          "Multiple Choice" = {
                            if (is.na(blockMap$Conditional.Type[i])) {
                              paste0(
                                '- takeScreenshot: "', id, '"\n',
                                '- swipe:\n',
                                '    start: 50%, 85%\n',
                                '    end: 50%, 55%\n',
                                '    duration: 400\n',
                                '- takeScreenshot: "', id, '_2"\n',
                                '- tapOn: "Right-facing arrow indicating next question"\n',
                                '- waitForAnimationToEnd\n',
                                '- tapOn: "OK"\n',
                                '- waitForAnimationToEnd'
                              )
                            } else {

                              comparator <- switch(as.character(blockMap$Conditional.Type[i]),
                                                   "1" = "=", "2" = "<=", "3" = ">=",
                                                   "4" = "<", "5" = ">", "6" = "!="
                              )

                              threshold <- blockMap$Conditional.Threshold[i]
                              qid <- blockMap$Question.ID[i]

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
                                '- takeScreenshot: "', id, '"\n',
                                '- swipe:\n',
                                '    start: 50%, 85%\n',
                                '    end: 50%, 55%\n',
                                '    duration: 400\n',
                                '- takeScreenshot: "', id, '_2"\n',
                                '- tapOn: "', definition, '"\n',
                                '- waitForAnimationToEnd\n',
                                '- tapOn: "Right-facing arrow indicating next question"\n',
                                '- waitForAnimationToEnd'
                              )
                            }
                          },
                          "Multiple Slider" = {
                            paste0(
                              '- takeScreenshot: "', id, '"\n',
                              '- swipe:\n',
                              '    start: 50%, 85%\n',
                              '    end: 50%, 55%\n',
                              '    duration: 400\n',
                              '- takeScreenshot: "', id, '_2"\n',
                              '- tapOn: "Right-facing arrow indicating next question"\n',
                              '- waitForAnimationToEnd\n',
                              '- tapOn: "OK"\n',
                              '- waitForAnimationToEnd'
                            )
                          },
                          "Slider" = {
                            paste0(
                              '- takeScreenshot: "', id, '"\n',
                              '- tapOn: "Right-facing arrow indicating next question"\n',
                              '- waitForAnimationToEnd\n',
                              '- tapOn: "OK"\n',
                              '- waitForAnimationToEnd'
                            )
                          },
                          "End Block" = {
                            NULL
                          },
                          "Informational Fullscreen" = {
                            paste0(
                              '- takeScreenshot: "', id, '"\n',
                              '- tapOn: "Right-facing arrow indicating next question"\n',
                              '- waitForAnimationToEnd'
                            )
                          },
                          {
                            warning("Unrecognized type at row ", i, ": ", type)
                            NA
                          }
    )

    yamlLines <- c(yamlLines, yamlCommand)
  }

  fullYaml <- paste(yamlLines, collapse = "\n")

  if (!shiny) {
    cat(fullYaml)
  }

  writeLines(fullYaml, "output.yaml")

  invisible(fullYaml)
}




library(jsonlite)
url <- "https://wearables.vmhost.psu.edu/wearables-survey/Survey/blockStructure?s_id=75&g_id=1045"

df <- fromJSON(url, simplifyVector = F, flatten = T)

df[[1]][["bsss"]][[2]]

sapply(df[[1]][["bsss"]], function(surveyNum) {str(surveyNum, max.level = 2)})


lapply(df[[1]][["bsss"]], function(x) {
  lapply(x[["survey"]][["surveyDataItems"]], function(item) {
    # If conditional exists...
    if (item$conditionalLimit != 0) {
      # If Question just grab once
      if(item$type == 'question') {
        qID <- item$sQuId
      }

      # If block grab for each item in the block
      if(item$type == 'block') {
        lapply(item[["blockitems"]], function(blockItem) {

        })
      }


    }
  })
})

sapply(df[[1]][["bsss"]][["survey"]], function(survey) {
  sapply(survey[["surveyDataItems"]], function(item) {
    str(item)
    if (item$conditionalLimit != 0) {

    }
  })
})
# Question id
sQuId
