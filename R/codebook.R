require(pacman)
p_load(knitr)
p_load(dplyr)

# Ensure directory is set (temp default)
#setwd(dirname(normalizePath(sys.frame(1)$ofile)))


# Load function defaults
#defaults <- as.list(formals(generate_codebook))
#list2env(defaults, envir = .GlobalEnv)
#rm(defaults)
#thisData = read.csv("processedData/surveyCombined.csv")
#blockMap = read.csv("processedData/questionMap.csv")
#responseKey = read.csv("processedData/responseMap.csv")


generate_codebook <- function(title = "This is a temp default title, please set",
                              authors = "This is a temp default author list, please set",
                              funding = "This is a temp default funding source, please set",
                              abstract = "This is a temp default abstract, please set",
                              summary = "This is a temp default summary, please set",
                              thisData = read.csv("processedData/surveyCombined.csv"),
                              blockMap = read.csv("processedData/questionMap.csv"),
                              responseKey = read.csv("processedData/responseMap.csv"),
                              include_practice_items = FALSE,
                              include_html = FALSE,
                              print_blockmap_missing = FALSE,
                              generate_item_description = TRUE,
                              # Name of the file to be created
                              output_file = "Codebook.html") {

  # This is a temp default that should be filed into the processing step, this is to clean fambes data specifically
  thisData[] <- lapply(thisData, function(x) {
    if (is.character(x)) x[tolower(x) == "n/a"] <- NA
    x
  })

  # Add to data processing later
  if ("Item" %in% names(thisData)) {
    names(thisData)[names(thisData) == "Item"] <- "Item.ID"
  }

  if ("question" %in% names(responseKey)) {
    names(responseKey)[names(responseKey) == "question"] <- "Question.ID"
  }

  #responseKey <- responseKey %>%
  #  left_join(blockMap[, c("Question.ID", "Item.ID")], by = "Question.ID", relationship = "many-to-many")


  # Temp default ~ Ethan
  #responseKey <- responseKey %>%
  #  group_by(Item.ID) %>%
  #  filter(Question.ID == first(Question.ID)) %>%
  #  ungroup()

  # Ensure logical args are set
  # Helper function to check that args are set to logical
  check_logical <- function(x, name = deparse(substitute(x))) {
    if(!is.logical(x) || length(x) != 1) {
      stop(paste0("Please set ", name, " to a logical argument of either 'TRUE' or 'FALSE'"), call. = TRUE)
    }
  }

  # Call check_logical on needed variables
  check_logical(include_practice_items)
  check_logical(print_blockmap_missing)
  check_logical(include_html)

  ### Process data ###

  # Practice items
  # Process practice items (practice item processing not supported)
  if (include_practice_items == TRUE) {
    stop("Processing of practice items is not supported in this version of the realtime science lab codebook generation tool")
  } else {
    cat("Removing practice items...\n")
    blockMap <- blockMap[!grepl("Practice", blockMap$Survey, ignore.case = TRUE), ]
  }

  # If Item.Type == Block add type 'Block' in Question.Type.Display.Name
  blockMap$Question.Type.Display.Name[
    blockMap$Item.Type == "Block" & is.na(blockMap$Question.Type.Display.Name)] <- "Block"

  # Remove NA question types
  # Check if there are any NA's data types and ask if user is okay removing them
  if (any(is.na(blockMap$Question.Type.Display.Name))) {

    if (print_blockmap_missing == TRUE) {
      print(blockMap[is.na(blockMap$Question.Type.Display.Name), ] > 0 )
    }

    repeat {

      # Prompt user how to continue
      cat("Rows with NA values for 'Question.Type.Display.Name' detected in block map (set 'print_blockmap_missing = TRUE' to see problem rows).\n")
      response <- readline(prompt = "NA item type rows will be dropped. Do you want to continue knitting? (y/n): ")

      # If yes, continue knit call
      if (tolower(response) == "y") {
        cat("Continuing knit call... \n")
        break

        # If no, stop knit call
      } else if (tolower(response) == "n") {
        stop("Stopping knit call")

        # If invalid return to top of call
      } else {
        cat("Error, wrong response input, please respond 'y' or 'n'\n")
      }
    }
  }


  # Drop rows with NA values in Question Type Display Name
  cat("Removing Block Map rows with 'NA' values in Question.Type.Display.Name ...\n")
  blockMap <- blockMap[!is.na(blockMap$Question.Type.Display.Name), ]



  # HTML formatting
  # Process html formatting
  if (include_html == TRUE) {
    stop("Processing of html is not supported in this version of the realtime science lab codebook generation tool")
  } else {
    cat("Removing html formatting from Question.Text ...\n")
    blockMap$Question.Text <- gsub("<[^>]+>", "", blockMap$Question.Text)
    blockMap$Question.Text <- gsub('[\"“”‘’\']', '', blockMap$Question.Text)
  }

  # Unsupported data types
  # Check unique data types
  data_types <- unique(blockMap$Question.Type.Display.Name)

  unsupported_data_types <- character()

  # Index data types
  for (data_type in data_types) {

    # Clean out spaces
    data_type_no_space <- gsub(" ", "", data_type)
    # Check for rmd files
    if (!file.exists(paste0("DataTypes/", data_type_no_space, ".Rmd"))) {
      # If does not exists add to vector
      unsupported_data_types <- c(unsupported_data_types, data_type)
    }

  }

  # If there are any unsupported data types....
  if (length(unsupported_data_types) > 0) {

    # Paste error msg and display unsupported types
    cat("The following question types are not supported by this version of the Real Time Science lab codebook generation tool:\n")
    cat(paste("-", unsupported_data_types), sep = "\n")

    repeat {

      # Prompt user how to continue
      response <- readline(prompt = "Questions with unsupported data types will be dropped. Do you want to continue knitting? (y/n): ")

      # If yes, continue knit call
      if (tolower(response) == "y") {
        cat("Continuing knit call... \n")
        break

        # If no, stop knit call
      } else if (tolower(response) == "n") {
        stop("Stopping knit call")

        # If invalid return to top of call
      } else {
        cat("Error, wrong response input, please respond 'y' or 'n'\n")
      }
    }
  }
  # Drop unsupported data types
  cat("Dropping unsupported data types ... \n")
  blockMap <- blockMap[!(blockMap$Question.Type.Display.Name %in% unsupported_data_types), ]


  # Render codebook
  # Save temp workspace
  save.image(file = "temp_workspace.RData")
  # Render codebook
  rmarkdown::render(
    input = "Highest-level-template.Rmd",
    output_file = output_file,
    params = list(
      title = title,
      authors = authors
    )
  )
  # Remove temp workspace
  file.remove("temp_workspace.RData")

}
