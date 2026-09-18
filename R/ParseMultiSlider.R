# Function that makes multislider respones rows in blockMap. Unused currently.

parseMultiSlider <- function(blockMap, responseKey) {

  isSlider <- blockMap$Question.Type.Display.Name == "Multiple Slider" &
    !is.na(blockMap$Question.Type.Display.Name)

  sliderIds <- unique(blockMap$Question.ID[isSlider])

  # temp column to control row order after inserting duplicates
  blockMap$.ord <- seq_len(nrow(blockMap))

  newRows <- list()

  for (id in sliderIds) {
    labels <- unique(responseKey$definition[responseKey$question %in% id &
                                              !is.na(responseKey$definition) & responseKey$type == "Multi Slider"])
    if (length(labels) == 0) next

    # parent row for this slider
    parent <- blockMap[isSlider & blockMap$Question.ID == id, ][1, ]

    # one copy of the parent per label
    dupes <- parent[rep(1, length(labels)), ]
    dupes$Question.Text <- labels

    # slot the duplicates directly after the parent
    dupes$.ord <- parent$.ord + seq_along(labels) / (length(labels) + 1)

    newRows[[as.character(id)]] <- dupes
  }

  if (length(newRows) > 0) {
    blockMap <- rbind(blockMap, do.call(rbind, newRows))
  }

  blockMap <- blockMap[order(blockMap$.ord), ]
  blockMap$.ord <- NULL
  rownames(blockMap) <- NULL

  blockMap
}

# usage
test <- parseMultiSlider(blockMap = blockMap,responseKey =responseKey)
