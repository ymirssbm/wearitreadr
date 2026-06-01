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


  # Grab list of surveys
  surveys <- unique(na.omit(blockMap$Survey))

  # Fall back on long name if surveys is empty
  if (is.null(surveys) || length(surveys) == 0) {
    blockMap$Survey <- blockMap$Survey.LongName
    surveys <- unique(na.omit(blockMap$Survey))
  }

  #browser()
  # For each survey
  for (survey in surveys) {

    # Call survey page
    out2 <- paste(
      out2,
      knit_expand(
        file = get_resource_path("Codebook_RMD", "Survey.Rmd"),
        survey_name = survey
      )
    )

    # Ensure that a level 3 header is created, it will be invisible, but then if a level 4 comes after it it will respect hierarchy
    # out2 <- paste(out2, "### ", sep = "\n") Need to find a fix for this because I cant make this work this way ~ Ethan

    surveyBlock <- blockMap[(blockMap$Survey == survey & !is.na(blockMap$Survey)), ]

    items <- unique(surveyBlock$Item.ID)

    # Make index for tracking what has been initialized
    index <- c()

    # For each item surveyBlock
    for (item in items) {
      itemBlock <- surveyBlock[(surveyBlock$Item.ID == item),]

      if (item %in% index) {
        next
      }

      # Positional index of item in items
      loopNum <- which(items == item)
      # Record that we have looped this item
      index[loopNum] <- item

      # This just contains the child if no parent
      parentChildBlock <- itemBlock

      # If item is a child and parent hasnt been knitted, knit it then knit child
      #browser()
      if (itemBlock$childTrue == TRUE & !(itemBlock$Parent %in% index)) {
        parentBlock <- surveyBlock[(surveyBlock$Item.ID == itemBlock$Parent),]
        parentChildBlock <- rbind(parentBlock, itemBlock)

        # Mark parent as processed
        index[which(items == parentBlock$Item.ID)] <- parentBlock$Item.ID

      }

      for (i in 1:nrow(parentChildBlock)) {
        itemBlock <- parentChildBlock[i,]

        # If block, knit block rmd
        if (nrow(itemBlock) == 1 && itemBlock$Item.Type == "Block") {

          # Initalize chunk label for block
          chunk_label <- paste(itemBlock$Question.Type.Display.Name, itemBlock$Question.ID, item)
          chunk_label <- gsub(" ", "-", chunk_label)
          # Fail safe to clean any special characters that sneak in
          chunk_label <- gsub("[^A-Za-z0-9\\-]", "", chunk_label)

          # Knit expand block rmd
          out2 <- paste(
            out2,
            knit_expand(
              file = get_resource_path("Codebook_RMD", "DataTypes", "Block.Rmd"),
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
        if(nrow(itemBlock) == 1 && itemBlock$Item.Type == "Question") {
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
              file = get_resource_path("Codebook_RMD", "DataTypes", "QuestionPage.Rmd"),
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
              file = get_resource_path("Codebook_RMD", "DataTypes", paste0(question_type_no_space, ".Rmd")),
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
