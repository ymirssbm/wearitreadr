#' List Question Ids
#'
#' This lists the question ids associated with an item as a tabset so that you can link back out to question page
#' Put results = 'asis' and echo = FALSE in codechunk block
#'
#' @param id Item ID number
#' @param blockMap df containing blockMap
#' @return Text on the item pages
#' @export


listQuestionIds <- function(id, blockMap) {
  cat("#### Surveys/Questions\n\n")

  # Grab question ids associated with this item id
  question_ids <- unique(blockMap$Question.ID[blockMap$Item.ID == id])

  cat("This Item appears in these surveys \n")

  # Loop through question ids
  for (qid in question_ids) {
    survey <- unique(blockMap$Survey[blockMap$Question.ID == qid])
    survey <- survey[!is.na(survey)]
    cat(
      paste0(
        '<div>',
        '<span style="font-weight: bold; color: #2a5caa;"><a href="#', qid, '-anchor">[', qid, ']</a></span>: ',
        paste(survey),
        '</div>\n'
      )
    )
  }
}
