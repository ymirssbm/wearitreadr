#' Describe By Item
#'
#' This generates a codebook grouping by items.
#' That is, if a question is asked across multiple surveys, this will describe the item across all times it appears in a studies dataset
#'
#' @param out2 Character string containing text to be knitted
#' @param thisData Dataframe containing data
#' @param blockMap df containing blockMap
#' @param responseKey df containing responseKey
#' @return out2 or a character string to be knitted
#' @export
#' @importFrom dplyr arrange %>% group_by summarise rename distinct left_join
#' @importFrom knitr knit_expand
#' @importFrom kableExtra kable_styling column_spec


describeByItem <- function(out2, thisData, blockMap, responseKey) {


  n <- length(unique(thisData$Participant.ID))

  out2 <- paste(out2, "# By Item Description", sep = "\n")


  # Write over question id in this data
  thisData_item <<- thisData
  thisData_item$Question.ID <<- thisData_item$Item.ID
  #responseKey <- responseKey %>% rename(Question.ID = question) # Add into data processing script probably ~ Ethan
  # Write over question id with item id
  responseKey_item <<- responseKey %>%
    left_join(
      blockMap %>%
        group_by(Question.ID) %>%
        summarise(Item.ID = first(Item.ID), .groups = "drop"),
      by = "Question.ID"
    ) %>%
    rename(Old.Question.ID = Question.ID,
           Question.ID = Item.ID) %>%
    distinct(Question.ID, value, definition, .keep_all = TRUE)


  # Grab just items not blocks
  blockMap_item <<- blockMap[(blockMap$Item.Type == "Question"),]
  # Coerce questions ids to be item ids
  blockMap_item$Question.ID <<- blockMap_item$Item.ID
  # Grab 1 row for each unique item id
  blockMap_item <<- blockMap_item %>%
    distinct(Item.ID, .keep_all = TRUE)



  items <- unique(blockMap_item$Item.ID)

  # For each item blockBlock
  for (item in items) {
    itemBlock <- blockMap_item[(blockMap_item$Item.ID == item),]



    # If Question, knit respective question rmd file
    if(itemBlock$Item.Type == "Question") {
      attach(itemBlock)
      question_type <- itemBlock$Question.Type.Display.Name
      question_type_no_space <- gsub(" ", "", question_type)

      # Grab chunk labels
      chunk_label <- paste("By Item Description", itemBlock$Question.Type.Display.Name, itemBlock$Question.ID, item)
      chunk_label <- gsub(" ", "-", chunk_label)
      # Fail safe to clean any special characters that sneak in
      chunk_label <- gsub("[^A-Za-z0-9\\-]", "", chunk_label)


      # Knit Item Page
      out2 <- paste(
        out2,
        knit_expand(
          file = get_resource_path("Codebook_RMD", "DataTypes_Item", "ItemPage.Rmd"),
          question_text = itemBlock$Question.Text,
          item_id = itemBlock$Item.ID,
          question_type = itemBlock$Question.Type.Display.Name,
          result_type = itemBlock$Result.Type,
          question_id = itemBlock$Question.ID,
          chunk_label = chunk_label,
          itemBlock = itemBlock
        )
      )


      # Knit expand
      out2 <- paste(
        out2,
        knit_expand(
          file = get_resource_path("Codebook_RMD", "DataTypes_Item", paste0(question_type_no_space, ".Rmd")),
          question_text = itemBlock$Question.Text,
          item_id = itemBlock$Item.ID,
          question_type = itemBlock$Question.Type.Display.Name,
          result_type = itemBlock$Result.Type,
          question_id = itemBlock$Item.ID,
          chunk_label = chunk_label,
          itemBlock = itemBlock,
          n = n
        )
      )
      detach(itemBlock)
    }
  }
  return(out2 = out2)
}
