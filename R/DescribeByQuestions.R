#' Describe By Question
#'
#' This generates a codebook by question. That is, a description of every unique instance of a question
#' If the question appears across multiple surveys, it will display a description of the question for each survey
#'
#' @param out2 Character string containing text to be knitted
#' @param thisData Dataframe containing data
#' @param blockMap df containing blockMap
#' @param responseKey df containing responseKey
#' @return out2 or a character string to be knitted
#' @export
#' @importFrom dplyr arrange %>%
#' @importFrom knitr knit_expand
#' @importFrom kableExtra kable_styling column_spec

describeByQuestion <- function(out2, thisData, blockMap, responseKey) {


  # Grab sample size (Probably need something to deal with weird ID names, fix later)
  n <- length(unique(thisData$Participant.ID))




  # Structure of this page is as follows....

  # Survey
  ## Block
  ### Question (which links out to item page)


  # Arrange item id to get order that PI put in items (but ensure that rows with a Parent of the survey always come first)
  blockMap <- blockMap %>%
    arrange(!(Parent %in% Survey), as.numeric(gsub("Item ", "", Item.ID)))

  # Grab list of surveys
  surveys <- unique(na.omit(blockMap$Survey))

  # For each survey
  for (survey in surveys) {

    # Call survey page
    out2 <- paste(
      out2,
      knit_expand(
        file = "Survey.Rmd",
        survey_name = survey
      )
    )

    # Ensure that a level 3 header is created, it will be invisible, but then if a level 4 comes after it it will respect hierarchy
    out2 <- paste(out2, "### ", sep = "\n")




    surveyBlock <- blockMap[(blockMap$Survey == survey & !is.na(blockMap$Survey)), ]

    # Grab list of blocks for survey i
    blocks <- unique(surveyBlock[(surveyBlock$Item.Type == "Block"),])

    # For each block
    for (i in 1:nrow(blocks)) {

      block <- blocks[i,]


      blockBlock <- surveyBlock[(surveyBlock$Parent == block$Item.ID),]
      items <- unique(blockBlock$Item.ID)

      # For each item blockBlock
      for (item in items) {
        itemBlock <- blockBlock[(blockBlock$Item.ID == item),]

        # If block, knit block rmd
        if (itemBlock$Item.Type == "Block") {

          # Initalize chunk label for block
          chunk_label <- paste(itemBlock$Question.Type.Display.Name, itemBlock$Question.ID, item)
          chunk_label <- gsub(" ", "-", chunk_label)
          # Fail safe to clean any special characters that sneak in
          chunk_label <- gsub("[^A-Za-z0-9\\-]", "", chunk_label)

          # Knit expand block rmd
          out2 <- paste(
            out2,
            knit_expand(
              file = paste0("DataTypes/Block.Rmd"),
              question_text = itemBlock$Question.Text,
              item_id = itemBlock$Item.ID,
              question_type = itemBlock$Question.Type.Display.Name,
              result_type = itemBlock$Result.Type,
              question_id = itemBlock$Question.ID,
              chunk_label = chunk_label,
              itemBlock = itemBlock,
              n = n)
          )
        }

        # If Question, knit respective question rmd file
        if(itemBlock$Item.Type == "Question") {
          attach(itemBlock)
          question_type <- itemBlock$Question.Type.Display.Name
          question_type_no_space <- gsub(" ", "", question_type)

          # Grab chunk labels
          chunk_label <- paste(itemBlock$Question.Type.Display.Name, itemBlock$Question.ID, item)
          chunk_label <- gsub(" ", "-", chunk_label)
          # Fail safe to clean any special characters that sneak in
          chunk_label <- gsub("[^A-Za-z0-9\\-]", "", chunk_label)


          # Knit Queston Page
          out2 <- paste(
            out2,
            knit_expand(
              file = paste0("DataTypes/QuestionPage.Rmd"),
              question_text = itemBlock$Question.Text,
              item_id = itemBlock$Item.ID,
              question_type = itemBlock$Question.Type.Display.Name,
              result_type = itemBlock$Result.Type,
              question_id = itemBlock$Question.ID,
              chunk_label = chunk_label,
              itemBlock = itemBlock
            )
          )


          # Knit Data type
          out2 <- paste(
            out2,
            knit_expand(
              file = paste0("DataTypes/", question_type_no_space, ".Rmd"),
              question_text = itemBlock$Question.Text,
              item_id = itemBlock$Item.ID,
              question_type = itemBlock$Question.Type.Display.Name,
              result_type = itemBlock$Result.Type,
              question_id = itemBlock$Question.ID,
              chunk_label = chunk_label,
              itemBlock = itemBlock,
              n = n
            )
          )
          detach(itemBlock)
        }
      }
    }
  }
  return(out2 = out2)
}
