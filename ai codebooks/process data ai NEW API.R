library(jsonlite)
library(dplyr)
library(lubridate)

parse_wearit_json <- function(filepath) {

  raw <- fromJSON(filepath, simplifyVector = TRUE, simplifyDataFrame = FALSE)

  # ── Helper: safely extract a field or return NA ──────────────────────────
  safe_get <- function(x, field, default = NA) {
    if (!is.null(x[[field]])) x[[field]] else default
  }

  # ════════════════════════════════════════════════════════════════════════
  # 1. DATA tibble
  # ════════════════════════════════════════════════════════════════════════
  d <- raw$data

  # If no data, return empty tibble with correct columns
  if (is.null(d)) {

    Data <- tibble(
      Survey.ID                  = numeric(),
      Survey.Name                = character(),
      Participant.ID             = character(),
      Session.ID                 = numeric(),
      Alert.Times                = as_datetime(character()),
      Survey.Start               = as_datetime(character()),
      Survey.Date.Completed      = as_datetime(character()),
      Survey.Date.Submitted      = as_datetime(character()),
      Timezone                   = character(),
      Offset                     = numeric(),
      Network.Type               = character(),
      App.Version                = character(),
      OS                         = character(),
      Model                      = character(),
      Burst                      = numeric(),
      UCS.ID                     = numeric(),
      User.Response              = character(),
      Question.ID                = character(),
      Item                       = character(),
      Short.Descriptor           = character(),
      External.ID                = character(),
      Cog.Test.Result            = logical(),
      Survey                     = character(),
      Block                      = logical(),
      Sub.block                  = logical(),
      Question.Text              = character(),
      Question.Type              = numeric(),
      Conditional.Child.Item.ID  = numeric(),
      Conditional.Fail.Item.ID   = numeric(),
      Conditional.Threshold      = numeric(),
      Conditional.Type           = numeric(),
      Conditional.Master.Item.ID = numeric(),
      Question.Type.Display.Name = character(),
      Result.Type                = character(),
      Multiple.Question.Type     = logical()
    )

  } else {

    # your existing logic
    n <- max(sapply(d[!sapply(d, is.null)], length))

    pad <- function(x, n, default = NA) {
      if (is.null(x) || length(x) == 0) rep(default, n) else unlist(x)
    }

    Data <- tibble(
      Survey.ID                  = pad(d$Survey.ID,                  n, NA_real_),
      Survey.Name                = pad(d$Survey.Name,                n, NA_character_),
      Participant.ID             = pad(d$Participant.ID,             n, NA_character_),
      Session.ID                 = pad(d$Session.ID,                 n, NA_real_),
      Alert.Times                = as_datetime(pad(d$Alert.Times,    n, NA_character_)),
      Survey.Start               = as_datetime(pad(d$Survey.Start,   n, NA_character_)),
      Survey.Date.Completed      = as_datetime(pad(d$Survey.Date.Completed,  n, NA_character_)),
      Survey.Date.Submitted      = as_datetime(pad(d$Survey.Date.Submitted,  n, NA_character_)),
      Timezone                   = pad(d$Timezone,                   n, NA_character_),
      Offset                     = pad(d$Offset,                     n, NA_real_),
      Network.Type               = pad(d$Network.Type,               n, NA_character_),
      App.Version                = pad(d$App.Version,                n, NA_character_),
      OS                         = pad(d$OS,                         n, NA_character_),
      Model                      = pad(d$Model,                      n, NA_character_),
      Burst                      = pad(d$Burst,                      n, NA_real_),
      UCS.ID                     = pad(d$UCS.ID,                     n, NA_real_),
      User.Response              = pad(d$User.Response,              n, NA_character_),
      Question.ID                = pad(d$Question.ID,                n, NA_character_),
      Item                       = pad(d$Item,                       n, NA_character_),
      Short.Descriptor           = pad(d$Short.Descriptor,           n, NA_character_),
      External.ID                = pad(d$External.ID,                n, NA_character_),
      Cog.Test.Result            = pad(d$Cog.Test.Result,            n, NA),
      Survey                     = pad(d$Survey,                     n, NA_character_),
      Block                      = pad(d$Block,                      n, NA),
      Sub.block                  = pad(d$Sub.block,                  n, NA),
      Question.Text              = pad(d$Question.Text,              n, NA_character_),
      Question.Type              = pad(d$Question.Type,              n, NA_real_),
      Conditional.Child.Item.ID  = pad(d$Conditional.Child.Item.ID,  n, NA_real_),
      Conditional.Fail.Item.ID   = pad(d$Conditional.Fail.Item.ID,   n, NA_real_),
      Conditional.Threshold      = pad(d$Conditional.Threshold,      n, NA_real_),
      Conditional.Type           = pad(d$Conditional.Type,           n, NA_real_),
      Conditional.Master.Item.ID = pad(d$Conditional.Master.Item.ID, n, NA_real_),
      Question.Type.Display.Name = pad(d$Question.Type.Display.Name, n, NA_character_),
      Result.Type                = pad(d$Result.Type,                n, NA_character_),
      Multiple.Question.Type     = pad(d$Multiple.Question.Type,     n, NA)
    )
  }
  # ════════════════════════════════════════════════════════════════════════
  # 2. BLOCKMAP tibble  — question is now an array, iterate over each
  # ════════════════════════════════════════════════════════════════════════
  sur       <- raw$burst$survey
  questions <- sur$question  # now a list of question objects

  blockMap <- bind_rows(lapply(questions, function(q) {
    ci <- q$Conditional.Info
    tibble(
      Survey.LongName            = safe_get(sur, "Survey.LongName",              NA_character_),
      Group                      = NA_real_,
      Survey.QID                 = NA_real_,
      Question.ID                = safe_get(q,   "Question.ID",                  NA_character_),
      Survey                     = safe_get(sur, "Survey.ShortName",             NA_character_),
      Item.ID                    = safe_get(q,   "Item.ID",                      NA_character_),
      Item.Type                  = safe_get(q,   "Item.Type",                    NA_character_),
      Parent                     = safe_get(q,   "Parent",                       NA_character_),
      `NA`                       = NA,
      Question.Text              = safe_get(q,   "Question.Text",                NA_character_),
      Question.Type              = NA_real_,
      Conditional.Child.Item.ID  = as.character(safe_get(ci, "Conditional.Child.Item.ID",  NA_character_)),
      Conditional.Fail.Item.ID   = as.character(safe_get(ci, "Conditional.Fail.Item.ID",   NA_character_)),
      Conditional.Threshold      = as.numeric(safe_get(ci,   "Conditional.Threshold",      NA_real_)),
      Conditional.Type           = as.character(safe_get(ci, "Conditional.Type",            NA_character_)),
      Conditional.Master.Item.ID = as.character(safe_get(ci, "Conditional.Master.Item.ID", NA_character_)),
      QID                        = safe_get(q,   "Question.ID",                  NA_character_),
      Question.Type.Display.Name = safe_get(q,   "Question.Type.Display.Name",   NA_character_),
      Result.Type                = safe_get(q,   "Data.Type",                    NA_character_),
      Multiple.Question.Type     = NA
    )
  }))

  # ════════════════════════════════════════════════════════════════════════
  # 3. RESPONSEKEY tibble — iterate over each question
  # ════════════════════════════════════════════════════════════════════════
  responseKey <- bind_rows(lapply(questions, function(q) {
    rk <- q$responseKey
    if (!is.null(rk) && length(rk) > 0) {
      bind_rows(lapply(rk, as.data.frame)) %>%
        mutate(
          survey   = safe_get(sur, "Survey.ShortName",           NA_character_),
          question = safe_get(q,   "Question.ID",                NA_character_),
          type     = "Response",
          value    = as.numeric(value)
        ) %>%
        select(survey, question, type, value, definition)
    }
  }))

  if (is.null(responseKey) || nrow(responseKey) == 0) {
    responseKey <- tibble(
      survey     = character(),
      question   = character(),
      type       = character(),
      value      = numeric(),
      definition = character()
    )
  }
  # Grab list of surveys
  surveys <- unique(na.omit(blockMap$Survey))

  # Fall back on long name if surveys is empty
  if (is.null(surveys) || length(surveys) == 0 || surveys == "") {
    blockMap$Survey <- blockMap$Survey.LongName
  }

  list(Data = Data, blockMap = blockMap, responseKey = responseKey)
}

# ── Usage ─────────────────────────────────────────────────────────────────
result      <- parse_wearit_json("study_output.json")
Data        <- result$Data
blockMap    <- result$blockMap
responseKey <- result$responseKey


write.csv(blockMap, "../codebookApp/Codebook_RMD/Data/blockMap.csv")
write.csv(responseKey, "../codebookApp/Codebook_RMD/Data/responseKey.csv")
write.csv(Data, "../codebookApp/Codebook_RMD/Data/Data.csv")
#rm(list = ls())
