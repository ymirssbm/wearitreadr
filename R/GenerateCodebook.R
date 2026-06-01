#' Generate Codebook
#'
#' This generates a codebook for a studies WearIT data
#'
#' @param title Character string denoting the desired title
#' @param authors Character string listing study or codebook authors
#' @param funding Character string denoting funding sources
#' @param abstract Character string containing abstract of study
#' @param summary Character string containing summary of study findings
#' @param thisData Dataframe containing data
#' @param blockMap Dataframe containing blockMap
#' @param responseKey Dataframe containing responseKey
#' @param include_practice_items Logical indicating whether to include practice item in the data description - note... this is not supported currently
#' @param include_html Logical indicating whether to keep html formatting - note... html formatting for question text not supported currently
#' @param print_blockmap_missing Logical. If true, will display the rows with NA values for Question.Type.Display.Name of which, will be automatically removed
#' @param generate_item_description Logical indicating whether to include by item description
#' @return codebook.html file in Codebook_RMD folder
#' @export


generateCodebook <- function(title = "This is a temp default title, please set",
                              authors = "This is a temp default author list, please set",
                              funding = "This is a temp default funding source, please set",
                              abstract = "This is a temp default abstract, please set",
                              summary = "This is a temp default summary, please set",
                              thisData = read.csv("Data.csv"),
                              blockMap = read.csv("blockMap.csv"),
                              responseKey = read.csv("responseKey.csv"),
                              include_practice_items = FALSE,
                              include_html = FALSE,
                              print_blockmap_missing = FALSE,
                              generate_item_description = FALSE,
                              # Using shiny or not
                              shiny = FALSE,
                              codebookChunkDisplayOptions = c("title page", "name of study", "authors", "study metadata", "desired graphic", "funding",
                                                              "abstract", "effective summary", "data types",
                                                              "freeresponse", "informationalfullscreen", "multiplechoice", "multipleselect",
                                                              "multipleslider", "slider", "timepicker", "timescaleslider", "block", "endblock",
                                                              "variable pages", "histograms", "missingness page", "descriptives", "bar plot",
                                                              "frequency table", "type of data", "way question was delivered", "screenshot", "skip logic",
                                                              "include data"),
                              # Name of the file to be created
                              output_file = "Codebook.html") {


  # Fix output file path
  output_file <- normalizePath(output_file, mustWork = FALSE)

  # Remove all data if user selected
  if(!"include data" %in% codebookChunkDisplayOptions) {
    thisData <- thisData[0,]
    #write.csv(thisData, "Codebook_RMD/Data/Data.csv", row.names = TRUE)
  }

  # This is a temp default that should be filed into the processing step, this is to clean fambes data specifically
  thisData[] <- lapply(thisData, function(x) {
    if (is.character(x)) x[tolower(x) == "n/a"] <- NA
    x
  })
  thisData[] <- lapply(thisData, function(x) {
    if (is.character(x)) x[tolower(x) == "NA"] <- NA
    x
  })
  thisData[] <- lapply(thisData, function(x) {
    if (is.character(x)) x[tolower(x) == "na"] <- NA
    x
  })

  # Add to data processing later
  if ("Item" %in% names(thisData)) {
    names(thisData)[names(thisData) == "Item"] <- "Item.ID"
  }

  if ("question" %in% names(responseKey)) {
    names(responseKey)[names(responseKey) == "question"] <- "Question.ID"
  }

  newCols <- c("parentTrue", "childTrue")
  blockMap[,newCols] <- NA




  # Create boolean cols for parent and child status
  # For each row in blockMap
  for (i in 1:nrow(blockMap)) {
    # Set parentTrue
    if (blockMap$Item.ID[i] %in% blockMap$Parent) {
      blockMap$parentTrue[i] <- TRUE
    } else {
      blockMap$parentTrue[i] <- FALSE
    }

    # Set childTrue
    if (blockMap$Parent[i] %in% blockMap$Item.ID) {
      blockMap$childTrue[i] <- TRUE
    } else {
      blockMap$childTrue[i] <- FALSE
    }
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

      if (shiny == FALSE) {
        response <- readline(prompt = "NA item type rows will be dropped. Do you want to continue knitting? (y/n): ")
      }

      # If using shiny, default to Yes
      if (shiny == TRUE) {
        response <- "y"
        generate_item_description <- FALSE
      }


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

  # Shiny Data Type selection
    # Grab all data types
    dataTypes <- list.files(path = get_resource_path("Codebook_RMD", "DataTypes"))
    dataTypes <- sub("\\.Rmd$", "", dataTypes)
    # Grab user selected datatypes
    # If using app, get user selected, otherwise, use all available in DataTypes folder
    selectedDataTypes <- dataTypes[tolower(dataTypes) %in% codebookChunkDisplayOptions]


    # Keep only user selected
    blockMap <- blockMap[(gsub(" ", "", blockMap$Question.Type.Display.Name) %in% selectedDataTypes), ]


  # Check unique data types
  data_types <- unique(blockMap$Question.Type.Display.Name)

  unsupported_data_types <- character()

  # Index data types
  for (data_type in data_types) {

    # Clean out spaces
    data_type_no_space <- gsub(" ", "", data_type)
    # Check for rmd files
    if (!file.exists(file.path(get_resource_path("Codebook_RMD", "DataTypes"), paste0(data_type_no_space, ".Rmd")))) {
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
      if (shiny == FALSE) {
        response <- readline(prompt = "Questions with unsupported data types will be dropped. Do you want to continue knitting? (y/n): ")
      }

      # If using shiny, default to Yes
      if (shiny == TRUE) {
        response <- "y"
      }

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

  wd <- getwd()
  cat(wd)
  # Drop unsupported data types
  cat("Dropping unsupported data types ... \n")
  blockMap <- blockMap[!(blockMap$Question.Type.Display.Name %in% unsupported_data_types), ]

  # Save temp workspace
  render_env <- list2env(as.list(environment()), parent = globalenv())

  # Render codebook
  rmarkdown::render(
    input = get_resource_path("Codebook_RMD", "Highest-level-template.Rmd"),
    output_file = output_file,
    envir = render_env,
    params = list(
      title = title,
      authors = authors,
      # Display codechunk options (default in app and yaml is true for all)
      titlePage = "title page" %in% codebookChunkDisplayOptions,
      nameOfStudy = "name of study" %in% codebookChunkDisplayOptions,
      displayAuthors = "authors" %in% codebookChunkDisplayOptions,
      desiredGraphic = "desired graphic" %in% codebookChunkDisplayOptions,
      funding = "funding" %in% codebookChunkDisplayOptions,
      abstract = "abstract" %in% codebookChunkDisplayOptions,
      effectiveSummary = "effective summary" %in% codebookChunkDisplayOptions,
      displayMeta = "study metadata" %in% codebookChunkDisplayOptions,
      histogram = "histograms" %in% codebookChunkDisplayOptions,
      missingnessPage = "missingness page" %in% codebookChunkDisplayOptions,
      descriptives = "descriptives" %in% codebookChunkDisplayOptions,
      barPlot = "bar plot" %in% codebookChunkDisplayOptions,
      frequencyTableDisplay = "frequency table" %in% codebookChunkDisplayOptions,
      typeOfData = "type of data" %in% codebookChunkDisplayOptions,
      deliveryType = "way question was delivered" %in% codebookChunkDisplayOptions,
      screenshot = "screenshot" %in% codebookChunkDisplayOptions,
      skipLogic = "skip logic" %in% codebookChunkDisplayOptions
    )
  )
  cat("Saving codebook to:", output_file, "\n")
}
