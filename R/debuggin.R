#Trying to run everything manually

require(pacman)
p_load(conflicted)
p_load(plyr)
p_load(tidyverse)
p_load(lubridate)
p_load(hms)
p_load(crul)
p_load(curl)  # #TODO: Replace with CRUL functions
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
  output <- pivot_wider(awkTall, names_from="Column", values_from = "Value")
  output$Question.Type <- as.integer(output$Question.Type)
  output <- left_join(output, WearIT.blockTypes, by = join_by(Question.Type))
  output <- distinct(rbind.fill(old_block_map, output))
}


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


#####################################################################
load("~/R/Tim Lab/GIT R directory/wearitreadr/R/sysdata.rda")
#api
#oDamIenMARPrq6gUW4aHm11N5iaGvfQxpKS5BETVEesaX36uIfgyIsqtIueO
creds <- wearIT_authorize()
requestResults <- makeAllRequests(creds)





keepAll <- FALSE
metaCount <- 3
studyJSON <- requestResults
simpleMeta <- FALSE

metaJSON <- studyJSON
if(simpleMeta && metaCount >= length(studyJSON)) {
  metaJSON <- studyJSON[1:metaCount]
}



studyKey <- list()
block_map <- data.frame()
for(dataSet in metaJSON) {
  studyKey <- processSurveyMeta(dataSet, studyKey)
  block_map <- processBlockMap(dataSet$`Block IDs Map`, block_map)

}

#This is old
#studyKey$SurveyInfo <- dplyr::rename(studyKey$SurveyInfo, c("Survey.QID"="Survey.ID",
#                                                            "Survey.LongName"="Survey.Name"))

#This is new
#studyKey$SurveyInfo <- dplyr::rename(studyKey$SurveyInfo, c("Survey.ID"="Survey.QID",
 #                                                           "Survey.Name"="Survey.LongName"))


colnames(studyKey$SurveyInfo)


# Process Survey Questions
survey_data <- data.frame()
studyCount <- 1

#Very long for loop
for(a_data_set in studyJSON) {
  if(studyCount %% 100 == 0) {message("Processing set ", studyCount)}
  studyCount <- studyCount + 1
  survey_data <- processStudyData(a_data_set$data, survey_data)
}

survey_data <- dplyr::rename(survey_data, "Question.ID"="Question")
names(survey_data) <- gsub("[ ]", ".", names(survey_data))



responseMap=as.data.frame(studyKey$ResponseKey)
survey_info=as.data.frame(studyKey$SurveyInfo)

#Checking names

##Block maps
names(block_map)
names(BlockMap)

block_map <- dplyr::rename(block_map, "Item.ID"="Item")


#Things that are not on the rcc block map
#"Item.Type" "Parent" "QID"


##Response Keys
names(responseMap)
#names(ResponseKey)



##Survey info / data
names(survey_info)
#names(SurveyInfo)



#survey_answers <- survey_data |>
 # left_join(block_map, by=join_by(Question.ID, Item))

#survey_question_lookup <- survey_data |>
 # group_by(Survey.ID, Survey.Name, Question.ID, Item, Short.Descriptor) |>
  #group_keys()
#summarize()




#Save all as csv files
write.csv(survey_data, "Codebook_RMD/loadedData/survey_data.csv", row.names = FALSE)
write.csv(block_map, "Codebook_RMD/loadedData/block_map.csv", row.names = FALSE)
write.csv(survey_info, "Codebook_RMD/loadedData/survey_info.csv", row.names = FALSE)
write.csv(responseMap, "Codebook_RMD/loadedData/responseMap.csv", row.names = FALSE)

#############################################################
