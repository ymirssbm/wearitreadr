require(pacman)
p_load(conflicted)
p_load(plyr)
p_load(tidyverse)
p_load(lubridate)
p_load(hms)
p_load(crul)
p_load(curl)  # #TODO: Replace with CRUL functions
p_load(logger)
if(Sys.getenv("SINGULARITY_CONTAINER")=="") {
  p_load(keyring)  # Won't run if running on RC in a container
}
p_load(jsonlite)
p_load(collections)
conflict_prefer_all("dplyr", quiet=TRUE)
conflicts_prefer(hms::hms, curl::parse_date)

# # TODO: Put this in whichever package folder it should go in (inst?)
# WearIT.blockTypes <- ifelse(file.exists("question_types.csv"),
#                             read.csv("question_types.csv"),
#                             # Shim for RStudio development
#                             ifelse(rstudioapi::isAvailable(),
#                                    read.csv(file.path(rstudioapi::getActiveProject(),
#                                                "inst/question_types.csv")),
#                                    read.csv(system.file("inst", "question_types.csv",
#                                                         package="WearItReadR"))))


# getWearItCredentials
#
#   Accesses wear-it keys, base URLs, etc. Uses Keyring if possible; defaults
#     to searching for a file if keyring fails.
#
# @param [String] studyID A file containing just the study ID number
# @param [String] keyFile A file containing just the app key file location
# @param [String] baseURL Base URL, in case you have a variant server
#
# @return A list containing the auth string and data URL.
wearIT_authorize <- function(study_ID = "1045",
                             base_URL = "https://wearables.vmhost.psu.edu/wearables-survey/api",
                             fmt_date = "%YYYY-mm-dd",
                             key_name = "WearIT-API-key",
                             backup_key_file = "~/.auth/.wearit",
                             skip_keyring = TRUE,
                             ...) {

  dots <- list(...)
  if("use_keyring" %in% names(dots)) {
    skip_keyring <- !dots$use_keyring
  }
  # Attempt keyring access:
  keyring_support <- TRUE

  if (!isNamespaceLoaded("keyring") ||
      !keyring::has_keyring_support()) {
    keyring_support <- FALSE
    if(!skip_keyring) {
      warning("Cannot access system keyring. Check keyring access.")
    }
  } else {
    keyring_support <- FALSE
    if(!skip_keyring) {
      warning("Install the keyring package to save credentials in system keyring.")
    }
  }

  auth <- NULL
  got_key <- FALSE

  if(keyring_support & !skip_keyring) {
    if(interactive()) {
      message("Fetching auth tokens; if asked, please authorize R ",
              "to access the system keychain.")
    }

    if(nrow(key_list(service = key_name))>0) {
      auth <- keyring::key_get(key_name)
    }
  }

  if(is.null(auth)) {  # Keyring failed or skipped; try files
    message("Checking for auth file.")
    auth <- tryCatch(sub("\n$", "", readChar(backup_key_file,
                                             file.info(backup_key_file)$size)),
                     error=\(x) NULL)
  } else {
    got_key <- TRUE
  }

  if(is.null(auth)) { # File failed, too.
    auth <- readline(prompt="Please enter your Wear-IT API authentication key:")
  }

  # TODO: Authentication check before setting key.
  if(!skip_keyring & !got_key) {
    if(interactive()) {
      message("Saving auth tokens; if asked, please authorize R ",
              "to access the system keychain....")
    }
    tryCatch({key_set_with_value(key_name, password=auth); message("Key set.")},
             error=\(x) {print("Error setting key."); print(x)})
  }
  authkey <- paste0("?api_token=", auth)

  dataURL <- paste(base_URL, "getData", study_ID, sep="/")

  nextURL <- dataURL
  crulConn <- HttpClient$new(
    url = base_URL,
    opts = list(
      timeout = 10
    ),
    headers = list(
      api_token=auth
    )
  )

  return(list(args=list(api_token=auth), baseURL=base_URL,
              dataURL=dataURL, crulconn=crulConn, studyID = study_ID))
}


# MakeGetRequest
#
#   Makes a single get request from an open base URL
#
# @param URL The URL to grab from
# @param endpointInfo The credential results
#
# @return A list containing an updated data URL and a JSON output chunk


# MakeOneRequest
#
#   Makes a single request from an open base URL
#
# @param URL The URL to grab from
# @param endpointInfo The credential results
#
# @return A list containing an updated data URL and a JSON output chunk
makeOneRequest <- function(URL, endpointInfo, argList=list()) {
  # Assemble args string: args overwrite endpoint list
  argList <- c(endpointInfo$args[setdiff(names(endpointInfo$args), names(argList))], argList)
  argString <- paste(names(argList), argList, sep="=", collapse="&")
  if(str_detect(URL, '[?]')) {
    # Note: does not detect duplicate args.
    URL <- paste(URL, argString, sep="&")
  } else {
    URL <- paste(URL, argString, sep="?")
  }

  output <- curl_fetch_memory(URL) # TODO: Replace with CRUL functions.
  # Process to sensible code:
  output$content <- rawToChar(output$content)
  output$headers <- read_lines(output$headers)

  # Handle errors for easier debugging:
  if(output$status_code != "200") {
    stop("Got an error from the server.", output)
  }

  # Handle JSON:
  output$json <- jsonlite::fromJSON(output$content, simplifyVector = FALSE)
  output
}

# MakeAllRequest
#
#   Makes a single request from an open base URL
#
# @param authList A Wear-IT authorization list, as returned from
#
# @return A list containing an updated data URL and a JSON output chunk

makeAllRequests <- function(creds, argList=list(),
                            upto=5000, verbose=FALSE) {  # 50limit for testing.

  requestStash <- list()
  jsonOutput <- list()
  nextURL <- creds$dataURL
  endpointInfo <- creds
  requestIdx <- 1
  while(requestIdx <= upto) {
    if(verbose) {
      if(verbose > 2 || !(requestIdx %% 50)) {
        print(paste("Requesting page ", requestIdx))
      } else {
        print(paste0(rep(".", requestIdx), collapse=""))
      }
    }
    requestStash[[requestIdx]] <- makeOneRequest(nextURL, endpointInfo, argList)
    if(is.null(requestStash[[requestIdx]]$json$links$`next`)) {
      break;
    }
    jsonOutput[[requestIdx]] <- requestStash[[requestIdx]]$json
    nextURL <- jsonOutput[[requestIdx]]$links$`next`
    requestIdx <- requestIdx + 1
  }
  if(verbose) {message("Ran ", requestIdx, " requests.")}
  if(requestIdx >= upto) {
    warning("Rate Limit hit; increase upto.")
  }
  return(jsonOutput)
}

# Get participation dates:
getParticipationDates <- function(data, participants, column='Survey Date Completed') {

  outs <- list()
  for(aParticipant in participants) {
    outs[[aParticipant]] <- unique(date(data[data['Participant ID']==aParticipant,column]))
  }
  if(length(outs) == 1) {outs <- outs[[1]]}
  return(outs)
}

# Gets and parses fitbit data for a participant for a data range/
getFitbitData <- function(participant, datelist, endpointInfo,
                          argList=list(), endpoint="getFitbitData", verbose=FALSE) {
  fitbitBaseURL <- paste(endpointInfo$baseURL, endpoint,
                         endpointInfo$studyID, participant, sep="/")
  fitList <- list()
  sleepTimes <- data.frame()
  allBouts <- data.frame()
  fitbitData <- data.frame()
  for(aDate in datelist) {
    aDate <- as_date(aDate)
    if(verbose) {
      print(paste("Retrieving", aDate))
    }
    nextURL <- paste(fitbitBaseURL, aDate, sep="/")
    response <- makeOneRequest(nextURL, endpointInfo, argList)
    newData <- response$json

    # browser()
    # Process Fitbit data
    header <- data.frame(`Partipant ID`=newData$ParticipantID,
                         date = ymd(newData$Date))

    fitList <- c(fitbitData, newData)
    # Process Heart rate
    # HR <-

    # Process sleep
    sleepBouts <- newData$Sleep$sleep
    for(aBout in sleepBouts) {
      # Summary-level
      newSleep <- cbind(header,
                        as.data.frame(aBout[setdiff(names(aBout), "levels")]))
      newSleep$startTime <- ymd_hms(newSleep$startTime)
      newSleep$endTime <- ymd_hms(newSleep$endTime)

      sleepTimes <- rbind.fill(sleepTimes, newSleep)

      # Bout-by-bout
      newBouts <- as.data.frame(t(sapply(aBout$levels$data,
                                         function(x) {t(unlist(x, use.names = TRUE))})))
      # browser()
      names(newBouts) <- c("Start", "Level", "Duration")
      newBouts$Start <- ymd_hms(newBouts$Start)
      newBouts$End <- newBouts$Start + seconds(newBouts$Duration)
      allBouts <- rbind.fill(allBouts, cbind(header, newBouts))
    }

  }

  # Extract sleep time characteristics
  sleepTimes <- sleepTimes %>%
    mutate(startTimestamp =startTime,
           endTimestamp = endTime,
           startTime = as_hms(startTimestamp),
           endTime = as_hms(endTimestamp),
           startDate = as_date(startTimestamp),
           endDate = as_date(endTimestamp),
           rolledStart = if_else(startTime < hms(0,0,4),
                                 startTime+hms(0,0,24), startTime),
           rolledEnd   = if_else(  endTime < hms(0,0,4),
                                   endTime+hms(0,0,24),   endTime),
           meanStart = mean(rolledStart, na.rm=TRUE),
           meanEnd   = mean(rolledEnd  , na.rm=TRUE),
           meanStart = if_else(meanStart > hms(0,0,24), meanStart-hms(0,0,24), meanStart),
           meanEnd   = if_else(meanEnd   > hms(0,0,24), meanEnd  -hms(0,0,24), meanEnd  )
    )

  return(list(sleepTimes=sleepTimes, sleepBouts=allBouts, allFitBit=fitList))
}

# Draw a sleep plot:
# ggplot(filter(splitSleep, isMainSleep==TRUE), aes(x=startDate, y=startTime)) + geom_crossbar(stat="identity", color="blue", fill="blue", aes(ymin=startTime, ymax=endTime, group=startDate)) + geom_linerange(aes(y=hms(0,0,0), ymin=hms(0,0,0), ymax=hms(0,0,24))) + stat_summary(aes(x=startDate, yintercept=meanStart), geom="hline", fun="mean") + stat_summary(aes(x=startDate, yintercept=meanEnd), geom="hline", fun="mean")


parseStudyJSON <- function(studyJSON, keepAll=FALSE, simpleMeta=FALSE, metaCount=1) {

  # Process metadata
  metaJSON <- studyJSON
  if(simpleMeta && metaCount <= length(studyJSON)) {
    metaJSON <- studyJSON[1:metaCount]
  }

  studyKey <- list()
  block_map <- data.frame()
  for(dataSet in metaJSON) {
    studyKey <- processSurveyMeta(dataSet, studyKey)
    block_map <- processBlockMap(dataSet$`Block IDs Map`, block_map)

  }

  studyKey$SurveyInfo <- dplyr::rename(studyKey$SurveyInfo, c("Survey.QID"="Survey.ID",
                                                              "Survey.LongName"="Survey.Name"))
  # Process Response Types:
  # browser()

  # Process Survey Questions
  log_info("Processing Survey Questions.")
  survey_data <- data.frame()

  # Extract full set of just the data parts
  unwrappedJSON <- unwrap(studyJSON)  # Combine HTML pulls
  unwrappedData <- unwrappedJSON[names(unwrappedJSON) == "data"] # Get the data elements
  fullDataSet <- unwrap(unwrappedData)
  metaNames <- setdiff(names(fullDataSet[[1]]), "User Responses")

  ### TEMP FIX Filter out user responses without anything to get this to run ~ Ethan

  fullDataSet <- Filter(function(x) {
    !is.null(x$'User Responses') && length(x$'User Responses') > 0
  }, fullDataSet)

  # Complex unpacking: pull the data and non-data elments from each block and stack'em
  survey_data <- map_dfr(fullDataSet, \(x){data.frame(data.frame(t(unlist(x[metaNames]))), map_dfr(x$`User Responses`,unlist))})

  ####################### Changed studyDataSet to survey_data so it has proper name ~ Ethan




  # Note that this will only grab the first External ID.
  # TODO: Use a handleOneEntry() function that handles EIDs better
  # browser()

  # Handle Timezones (Ugh)
  # TZLookup <- c("US/Eastern"=0, "US/Central"=1,
  #               "US/Mountain"=2, "US/Pacific"=3)
  # if(!"timezone" %in% names(survey_data)) {
  #   survey_data$timezone <- NA
  # }
  # survey_data <- survey_data |>
  #   mutate(Survey.Date.Submitted = ymd_hms(Survey.Date.Submitted, tz="US/Eastern"))
  # if(any(is.na(survey_data$timezone))) {
  #   survey_data <-
  #     nc1 <- survey_data |>
  #     mutate(Survey.Completed.Temp = ymd_hms(Survey.Date.Completed, tz="US/Eastern"),
  #            tz_diff = floor(as.numeric(Survey.Date.Submitted - Survey.Completed.Temp,
  #                               unit="hours")))  |>
  #     group_by(External.ID) |>
  #       mutate(tz_diff = min(tz_diff, na.rm=TRUE),
  #              tz_infer = names(TZLookup[tz_diff])) |>
  #     group_by(External.ID) |>
  #       mutate(timezone = case_when(is.na(timezone) ~ min(tz_infer, na.rm=TRUE),
  #                                   .default=timezone)) |>
  #     ungroup() |> group_by(External.ID, timezone) |>
  #       mutate(Survey.Date.Completed =
  #                ymd_hms(Survey.Date.Completed, tz=unique(timezone))) |>
  #     select(-tz_infer, -Survey.Completed.Temp)
  #
  # }
  # TODO: fix time zone handling



  # names(studyKey$SurveyInfo) <- gsub("[ ]", ".", names(studyKey$SurveyInfo))

  # browser()

  ######### Adding a temp fix check to see if Question.ID is getting named Question, if so rename it ~ Ethan
  if("Question" %in% names(survey_data)) { names(survey_data)[names(survey_data) == "Question"] <- "Question.ID" }



  survey_answers <- survey_data |>
    left_join(block_map, by=join_by(Question.ID, Item))

  if(!"Short.Descriptor" %in% names(survey_data)) { survey_data$Short.Descriptor <- survey_data$Item} #this is a temporary default, and we'll need to figure out whether there's a better approach.
  if(!"Cog.Test.Result" %in% names(survey_data)) { survey_data$Cog.Test.Result <- rep(NA, nrow(survey_data))} #this is a temporary default, and we'll need to figure out whether there's a better approach.

  survey_question_lookup <- survey_data |>
    group_by(Survey.ID, Survey.Name, Question.ID, Item, Short.Descriptor) |>
    group_keys()
  #summarize()
  browser()

  survey_combined <- survey_data
  #survey_combined <- survey_data |>
  #  left_join(block_map, by=join_by(Question.ID, Item)) |>
  #  mutate(Short.Descriptor=
  #           case_when(is.na(Short.Descriptor) ~
  #                       Question.ID, .default=Short.Descriptor)) |>
  #  filter(!is.na(Result.Type) | Question.Type.Display.Name == "Multiple Slider")  # Remove Informationals and End Blocks
  # added in '| Question.Type.Display.Name == "Multiple Slider"' so that it didnt get rid of multiple slider ~ Ethan

  #  cognames <- list(names(cogtest_data), paste(names(cogtest_data), "cog", sep="."))
  #  cogtest_data <- cogtest_data |> rename(any_of(cognames))

  survey_wide <- survey_data |>
    mutate(Short.Descriptor=
             case_when(is.na(Short.Descriptor) ~
                         Question.ID, .default=Short.Descriptor)) |>
    select(-any_of(c("External.ID1", "External.ID2", "External.ID3"))) |>
    select(-Question.ID, -Item, -Cog.Test.Result) |>
    pivot_wider(names_from=c(Short.Descriptor),
                values_from=c(User.Response))

  return(list(questionMap=as.data.frame(studyKey$SurveyInfo),
              responseMap=as.data.frame(studyKey$ResponseKey),
              surveyData=as.data.frame(survey_wide),
              surveyCombined=as.data.frame(survey_combined)))
  #cogtest_data = as.data.frame(cogtest_data))) Just took this out ~ Ethan

  # Handle the stranger item types
  # id_Data <- processIdentifierData(studyJSON$IDlist)
  # response_data <- processCogTests(response_data, keepMetadata=keepAll)
  # response_data <- processVideo(response_data, keepMetadata=keepAll)

  # FitBitData

  # Transform data into sensible terms:
  # outputData <- makeDataFriendly()

}

# Build the question map, etc.
processSurveyMeta <- function(study, SurveyKey=list()) {
  # browser()

  # Process existing survey key
  ## Servey header data
  SurveyInfo <- data.frame()
  if("SurveyInfo" %in% names(SurveyKey)) {
    # Update for appending
    SurveyInfo <- SurveyKey$SurveyInfo
  }

  ## Response Key Information:
  ResponseKey <- data.frame()
  if("ReponseKey" %in% names(SurveyKey)) {
    ResponseKey <- SurveyKey$ResponseKey
  }

  ## Block map information
  block_map <- data.frame()
  if("BlockMap" %in% names(SurveyKey)) {
    block_map <- SurveyKey$BlockMap
  }

  # Widen the survey question bank
  surveyWide <- t(unlist(study$`Current Survey Questions`, use.names = TRUE)) %>%
    as.data.frame() %>%
    pivot_longer(everything(), names_to=c("Survey.Name", "Group", "Survey.ID"),
                 names_pattern = "(.+?)(?:: Group (.+))? ID (.+)",
                 values_to="Question.ID")


  # Retrieve survey blockmap
  ## TODO: Use once processBlockMap handles names faster than the slow map below.
  # if("Block IDs Map" %in% names(study)) {
  #   block_map <- processBlockMap(study$`Block IDs`, block_map)
  # } else {
  #   stop("No blockmap detected.")
  # }

  # Generate new Survey key for this survey.
  newKey <- study$`Survey Response Key`

  for(SID in names(newKey)) { # Survey ID
    aSurvey <- newKey[[SID]]
    if(length(aSurvey) == 0) {next;} # TODO: Handle one-button survey here.
    for(QID in names(aSurvey)) {   # Question ID
      aQuestion <- aSurvey[[QID]]
      for(aKeyType in names(aQuestion)) {  # Response Map
        aKey <- aQuestion[[aKeyType]]
        keyName <- sub("([.]*)\ Key", "\\1", aKeyType)
        for(aResponseSet in aKey) {
          for(aResponse in names(aResponseSet)) {
            aDefinition <- aResponseSet[[aResponse]]
            if(is.null(aDefinition)) {aDefinition = "" }
            ResponseKey <- rbind.fill(ResponseKey,
                                      data.frame(survey=SID, question=QID,
                                                 type=keyName, value=aResponse,
                                                 definition=aDefinition))
          }
        }
      }
    }
  }
  ResponseKey <- distinct(ResponseKey)

  # browser()
  newMap <- study$`Block IDs Map`
  parent_tree <- data.frame()
  for(SID in names(newMap)) {
    aSurvey <- newMap[[SID]]
    if(length(aSurvey) == 0) {next;}
    for(BID in names(aSurvey)) {
      anItem <- aSurvey[[BID]]
      itemQueue <- queue(items=list(list(Survey=SID, itemName=BID, theItem=anItem, parent=SID)))
      while(itemQueue$size() > 0) {
        itemInfo <- itemQueue$pop()
        anItem <- itemInfo$theItem
        # browser()
        if(!is.null(names(anItem)) && any(startsWith(names(anItem), "Item"))) {
          # This is a block.
          parent_tree <- rbind.fill(parent_tree, data.frame(Survey=itemInfo$Survey,
                                                            Item.ID=itemInfo$itemName,
                                                            Item.Type="Block",
                                                            Parent=itemInfo$parent))
          for(subItem in names(anItem)) {
            itemQueue$push(list(Survey=SID, itemName=subItem, theItem=anItem[[subItem]],
                                parent=itemInfo$itemName))
          }
        } else {
          # This is an item
          itemOutput <- unlist(anItem, use.names = TRUE)
          if(is.null(itemOutput)) itemOutput <- matrix()
          # browser()
          parent_tree <- rbind.fill(parent_tree, cbind(data.frame(Survey=itemInfo$Survey,
                                                                  Item.ID=itemInfo$itemName,
                                                                  Item.Type="Question",
                                                                  Parent=itemInfo$parent),
                                                       Column = names(itemOutput),
                                                       Value = itemOutput))

        }
      }
    }
  }

  parent_tree <- parent_tree |>
    mutate(  Survey=gsub("[_]", " ", Survey),
             Parent=gsub("[_]", " ", Parent),
             Item.ID=gsub("[_]", " ", Item.ID),
             Column = gsub("[_ ]", ".", Column)) |>
    pivot_wider(names_from="Column", values_from = "Value") |>
    mutate(Question.Type = as.integer(Question.Type),
           QID = sub("Question ([[:digit:]]+)", "Q_\\1", Question.ID, perl = TRUE)) |>
    left_join(WearIT.blockTypes, by=join_by(Question.Type)) |>
    bind_rows(block_map)
  block_map <- distinct(parent_tree)

  # Merge Question Info back into data set
  surveyMap <- full_join(surveyWide, block_map, by = join_by(Question.ID))
  surveyInfo <- distinct(bind_rows(SurveyInfo, surveyMap)) # Avoid duplicates

  # # TODO: Conditionals, Actions
  # ResponseKey <- left_join(ResponseKey, BlockMap, by=join_by(survey="SID", question="Question ID"))

  SurveyKey$BlockMap <- block_map
  SurveyKey$SurveyInfo <- surveyInfo
  SurveyKey$ResponseKey <- ResponseKey

  return(SurveyKey)
}

# Process the actual output into a data-frame-like arrangement.
processStudyData <- function(allStudies, StudyData=data.frame()) {
  allData <- data.frame()
  if(!nrow(StudyData) == 0) {
    allData <- StudyData
  }

  for(studyData in allStudies) {
    # Schlep to data frames
    metadata <- studyData[names(studyData) != 'User Responses']
    metadata <- as.data.frame(t(unlist(metadata, use.names = TRUE)))
    metadata$'Survey Date Completed' <- ymd_hms(metadata$'Survey Date Completed')
    metadata$'Survey Date Submitted' <- ymd_hms(metadata$'Survey Date Submitted')
    # Process responses:
    questionData <- studyData$'User Responses'
    # browser()
    for(userResponse in questionData) {
      allData <- rbind.fill(allData,
                            cbind(metadata,
                                  as.data.frame(t(unlist(userResponse,
                                                         use.names = TRUE)))))
    }
  }
  return(type.convert(allData, as.is=TRUE))
}


# Process a single data column
processColumn <- function(thisCol, thisKey, qName, NACodeSet=c("No Response", "%%"),
                          okCommas=NULL, ..., verbose=FALSE) {
  #browser()
  # if(qName == "Q_2446") {browser()}
  if(verbose) {warning(paste("Processing question", qName, "With Key:", nrow(thisKey)))}
  newCols <- data.frame()

  # if(interactive() && length(grep("Q_2426", qName))) { browser()}
  # Cases requiring splitting:
  if(nrow(thisKey) && any(thisKey$Type %in% c("Multiple", "Repeatable", "Root"))) {
    if(verbose){warning(paste("Question", qName, "needs to be split because it's a", thisKey$Type))}
    newCols <- processSubQuestions(thisCol, thisKey, qName, verbose = verbose)
  } else if(nrow(thisKey) && any(grep(",", thisCol)) && !thisKey$Type[1] %in% "Text") {
    message(paste("Question", qName, "(type", thisKey$Type, ") needs splits in rows:",
                  paste(grep(",", thisCol), collapse=",")))
    newCols <- processSubQuestions(thisCol, thisKey, qName, verbose = verbose)
  } else if(!is.null(thisKey) && nrow(thisKey)) {  # Key has a scale
    naIndices <- which(thisKey$Value %in% NACodeSet)
    naCode <- NA
    for(naIdx in naIndices) {
      naCode <- thisKey$Code[naIdx]
      thisCol[thisCol == naCode] <- NA
      thisKey <- thisKey[-naIdx,]  # Remove the NA code
    }

    # Annotate Simple Scales
    if(nrow(thisKey) == 2 && length(unique(na.omit(thisCol))) > nrow(thisKey)) {  # Scale
      lowerLimitName <- paste(qName, "Lower", sep='.')
      upperLimitName <- paste(qName, "Upper", sep='.')
      lowerLimit <- thisKey$Code[1]
      upperLimit <- thisKey$Code[2]
      addCols <- data.frame(rep(lowerLimit, length(thisCol)),
                            rep(upperLimit, length(thisCol)))
      names(addCols) <- c(lowerLimitName, upperLimitName)
      if(nrow(newCols)) {
        newCols <- cbind(newCols, addCols)
      } else {
        newCols <- addCols
      }

    }
    # Time pickers
    # else if {
    #
    # }
    # Recode Factors
    else if(nrow(thisKey) > 0) {
      if(is.character(thisCol)) {
        thisCol <- type.convert(gsub('"','', thisCol), as.is=TRUE)
      }
      thisCol <- factor(thisCol, levels=thisKey$Code, labels=thisKey$Value)
    } else {
      if(is.character(thisCol)) {
        thisCol <- type.convert(gsub('"','', thisCol), as.is=TRUE)
      }
    }

  }

  else {
    timeTest <- suppressWarnings(parse_date_time(thisCol, orders=c("ymd", "ymd_HMS")))
    if(any(!is.na(timeTest))) {
      if(all(hour(timeTest) == 0, na.rm = TRUE)) {
        dateTest <- suppressWarnings(parse_date(thisCol))
        if(any(!is.na(dateTest))) thisCol <- dateTest
      } else {
        # Is a time
        thisCol <- timeTest
        if(qName == "SurveyDateSubmitted") {
          timeTest <- suppressWarnings(parse_date_time(thisCol, orders=c("ymd", "ymd_HMS"), tz="US/Eastern"))
        }
      }
    }
  }
  if(qName %in% names(newCols)) {
    stop(paste("Question", thisQ, "was double-processed."))
  }
  thisCol <- data.frame(thisCol)
  names(thisCol) <- qName
  if(nrow(newCols)==0) {
    newCols <- thisCol
  } else {
    newCols <- cbind(thisCol, newCols)
  }
  return(newCols)

}

# Process a subquestion type
processSubQuestions <- function(thisCol, keyInfo, qName, subRequest=NA, verbose=FALSE) {

  if(verbose) {warning(paste("Splitting parts of", qName, "with Key", paste(as.character(keyInfo), collapse=" ")))}
  newCols <- data.frame()

  # if(startsWith(qName, "Q_2448")) {browser()}
  # Split the data column:
  splitCol <- strsplit(as.character(thisCol), ',')

  if("SubQuestion" %in% names(keyInfo)) {
    if(length(subRequest == 1) && is.na(subRequest)) {
      subRequest <- unique(keyInfo$SubQuestion)
    }
    for(subQuestion in subRequest){

      # Get the keys we care about
      thisKey <- filter(keyInfo, SubQuestion == subQuestion)
      thisKey$Type <- "SubQuestion"

      thisMatch <- paste0("^", subQuestion, ":([[:digit:]]+)$")
      # And the data we care about
      oneCol <- data.frame(sapply(splitCol,
                                  FUN = function(x) {
                                    found <- grep(thisMatch, x, value=TRUE)
                                    if(length(found)==0) return(NA)
                                    as.numeric(sub(thisMatch, "\\1", found))
                                  }))
      newName <- paste0(qName, "_", subQuestion)
      names(oneCol) <- newName
      oneCol <- processColumn(oneCol[,1], thisKey, newName, verbose=verbose)
      if(nrow(newCols)==0) {
        newCols <- oneCol
      } else {
        newCols <- cbind(newCols, oneCol)
      }
    }
  } else if(nrow(keyInfo) && any(keyInfo$Type %in% "MultipleCheck")) {
    fillIdxFun <- function(x, y, ...) {
      if(is.character(x)) {
        x <- type.convert(gsub('"','', x), as.is=TRUE)
      }
      v <- rep(NA, y);
      v[x] <- x;
      return(v)
    }
    newOut <- sapply(splitCol, fillIdxFun, y=nrow(keyInfo))
    names(newOut) <- paste(qName, 1:ncol(newOut), sep="_")
  } else {
    # Set the defaults
    fillFun <- function(x, y, ...) { # Fill values in
      if(is.character(x)) {
        x <- type.convert(gsub('"','', x), as.is=TRUE)
      }
      v <- rep(NA, y);
      v[1:length(x)] <- x;
      return(v)
    }
    y <- max(sapply(splitCol, length))
    cols <- NA
    if(any(keyInfo$Type %in% c("Multiple"))) {
      # Override for multiple-select
      fillFun <- function(x, y, cols) { # Fill values in slots with their IDs.
        if(is.character(x)) {
          x <- type.convert(gsub('"','', x), as.is=TRUE)
        }
        v <- rep(NA, y);
        names(v) <- cols;
        v[na.omit(x)] <- na.omit(x);
        return(v)
      }
      y <- nrow(keyInfo)
      cols <- keyInfo$Codes
    }

    newOut <- sapply(splitCol, fillFun,y=y, cols=cols)
    newOut <- data.frame(t(newOut))
    names(newOut) <- paste(qName, 1:ncol(newOut), sep="_")
    for(anOut in 1:ncol(newOut)) {
      thisKey <- keyInfo
      thisKey$Type <- "SubQuestion"
      thisNew <- processColumn(newOut[[anOut]], thisKey, names(newOut)[anOut], verbose=verbose)
      if(nrow(newCols)==0) {
        newCols <- thisNew
      } else {
        newCols <- cbind(newCols, thisNew)
      }
    }

  }
  return(newCols)
}

# getStudyData
#
#   Pulls down all the study JSON in raw format.  Mostly, this function just
#   makes repeated requests and concatenates the JSON data
#
#
# @param [String] study_ID A file containing just the study ID number # I CHANGED THIS FROM studyID to study_ID ~ ethan
# @param [String] keyFile A file containing just the app key
# @param [String] baseURL Base URL, in case you have a variant server
#
# @return A list containing the auth string and data URL.



getStudyData <- function(study_ID = "1045", backup_key_file = "~/.auth/.wearit",
                         base_URL = "https://wearables.vmhost.psu.edu/wearables-survey/api", ...) { # Removed a / at end of url ~ Ethan

  creds <- wearIT_authorize(study_ID = study_ID, backup_key_file = backup_key_file, base_URL = base_URL)
  requestResults <- makeAllRequests(creds)
  studyData <- parseStudyJSON(requestResults, simpleMeta = TRUE)

}



# Additional block-mapping stuff

blockType <- function(itemList) {

}

processBlockMap <- function(json_blockmap, old_block_map=data.frame()) {

  # browser()
  if(!is.list(json_blockmap) || !length(json_blockmap) || !any(sapply(json_blockmap, is.list))) {
    # Not unpackable
    return(json_blockmap)
  }

  # Figure out how to map out the Block structure?

  # Widens the listing set
  unlisting <- unlist(json_blockmap)
  names(unlisting) <- gsub("[ ]", "_", names(unlisting))
  awkWide <- data.frame(t(unlisting))
  awkTall <- pivot_longer(awkWide, cols=everything(),
                          names_pattern = "^(?:(\\w*)\\.)*(?:(Item\\w*)\\.)?(?:(Item\\w*)\\.)*(\\w+)\\.(\\w+)",
                          names_to=c("Survey", "Block", "Sub.block", "Item", "Column"),
                          values_to="Value") |>
    mutate(  Survey=gsub("[_]", " ", Survey),
             Block=gsub("[_]", " ", Block),
             Sub.block=gsub("[_]", " ", Sub.block),
             Item=gsub("[_]", " ", Item),
             Column = gsub("[_ ]", ".", Column))
  output <- pivot_wider(
    awkTall,
    names_from = "Column",
    values_from = "Value",
    values_fn = list(Value = function(x) x[[1]])  # Just take the first value temp defualt ~ Ethan
  )
  output$Question.Type <- as.integer(output$Question.Type)
  output <- left_join(output, WearIT.blockTypes, by = join_by(Question.Type))
  output <- distinct(rbind.fill(old_block_map, output))
}

# Survey Block Diagram
surveyBlockDiagram <- function(surveyInfo) {

}

mapConditionals <- function(x) {
  # e.g. : fromJSON(file="blockStructure-YASS.json")
  studyJSON <- x[[1]]
  for(aBurst in studyJSON$bsss) {
    theSurvey <- aBurst$survey$surveyDataItems
    surveyID <- aBurst$survey$surveyID
    surveyGroupID <- aBurst$survey$surveyGroupID
    surveyTitle <- aBurst$survey$surveyTitle
    for(anItem in theSurvey) {
      message("How'd you get here?")
      browser()
    }
  }

}

flattenBlockIDMap <- function(Map, edges=data.frame()) {
  if("Block IDs Map" %in% names(Map)) {
    Map <- Map$`Block IDs Map`
  }
  edgeLists <- list()
  edges <- data.frame()
  # Top-level names are not item names.
  for(aName in names(Map)) {
    aMap <- Map[[aName]]
    edgeLists = list(aName = flattenBlockIDMap_Helper(aMap, paste("Survey",aName, "_"), edges))
  }
  return(edgeLists)
}

flattenBlockIDMap_Helper <- function(Map, tName, edges) {
  for(aName in names(Map)) {
    if(is.integer(Map)) {
      return(edges)
    }
    aMap <- Map[[aName]]
    edges <- rbind.fill(edges, data.frame(From=tName, To=aName))
    edges <- flattenBlockIDMap_Helper(aMap, aName, edges)
  }
  return(edges)
}

edgeGraph <- function(edges) {
  edgeList <- as.vector(rbind(edges$From, edges$To))
  G <- make_graph(edgeList, directed = FALSE)
  btw_groups <- cluster_edge_betweenness(G)
  btw_groups <- btw_groups$membership
  plot(     G,
            vertex.color=btw_groups,  # Color groups
            vertex.size = 10,         # Changes vertex size
            vertex.shape = 'circle',  # Changes vertex shape
            asp = 1,                  # Spread out nodes
            layout = layout_as_tree   # vertical tree layout
  )
}

# Helper functions
s <- function(x, m=1) {
  str(x, max.level=m)
}

rollMorning <- function(x, cutoff=hms(0,0,12)) {
  x <- if_else(x < cutoff, x+hms(0,0,24), x)
  x
}
rollEvening <- function(x, cutoff=hms(0,0,12)) {
  x <- if_else(x > cutoff, x-hms(0,0,24), x)
  x
}

unroll <- function(x, cutoff=hms(0,0,0)) {
  x <- if_else(x > cutoff+hms(0,0,24), x-cutoff, x)
  x <- if_else(x < cutoff, x+hms(0,0,24), x)
  x
}

#' Read WearIT Survey data ----
#' @author Nelson Roque, \email{Nelson.Roque@@ucf.edu}
#' @export
#' @param original_data original, pre-processed data
#' @param unnested_data result of `unnest_cogtask_data()`
cogdata_validation <- function(original_data, unnested_data) {
  og_ids = unique(original_data$wearit_uuid)
  un_ids = unique(unnested_data$wearit_uuid)
  overlap_ids = intersect(og_ids, un_ids)
  len_overlap_check = length(overlap_ids) == length(og_ids)
  return(list(ids_overlap = overlap_ids,
              all_records_processed = len_overlap_check))
}

unwrap <- function(x) {unlist(x, recursive=FALSE)}

#' Read WearIT Survey data ----
#'
#' \code{unnest_cogtask_data} unnests M2C2 Cogtask JSON data from WearIT platform
#' @author Nelson Roque, \email{Nelson.Roque@@ucf.edu}
#' @export
#' @importFrom tibble tibble
#' @importFrom dplyr arrange
#' @importFrom readr read_csv
#' @importFrom jsonlite fromJSON
#' @param data data object returned from `cogdata_preprocess()`
cogdata_unnest <- function(.data) {
  nested <- .data %>% filter(!is.na(Cog.Test.Result))
  unnested <- nested %>%
    mutate(json = map(Cog.Test.Result, ~ jsonlite::fromJSON(.) %>% as.data.frame())) %>%
    unnest(json) %>%
    arrange(Survey.Date.Completed) %>%
    select(-Cog.Test.Result)
  return(unnested)
}





# Save data from getStudyData to a csv in processedData

saveData <- function(data) {
  write.csv(data$questionMap, "Codebook_RMD/processedData/questionMap.csv", row.names = FALSE)
  write.csv(data$responseMap, "Codebook_RMD/processedData/responseMap.csv", row.names = FALSE)
  write.csv(data$surveyData, "Codebook_RMD/processedData/surveyData.csv", row.names = FALSE)
  write.csv(data$surveyCombined, "Codebook_RMD/processedData/surveyCombined.csv", row.names = FALSE)

}
