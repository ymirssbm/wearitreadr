#' Parse WearIt JSON Export
#'
#' Reads a WearIt study JSON file (0.1.0 spec) and extracts three structured
#' data objects: participant response data, a block map of survey questions,
#' and a response key mapping numeric values to their labels. Writes all
#' three to CSV files as a side effect.
#'
#' @param filepath Character string. Path to the WearIt JSON export file
#'   (e.g., \code{"study_output.json"}).
#'
#' @return Invisibly returns \code{NULL}. As a side effect, writes three CSV
#'   files to the same directory as \code{filepath}:
#'   \describe{
#'     \item{Data.csv}{One row per participant/session, containing the
#'       column-vector fields defined under the top-level \code{data}
#'       property of the 0.1.0 schema.}
#'     \item{blockMap.csv}{One row per question per survey, matching the
#'       column set expected by \code{generateSurveyFlowchart()} and the
#'       codebook generator.}
#'     \item{responseKey.csv}{One row per response option per question,
#'       mapping numeric values to their text definitions for closed-ended
#'       items.}
#'   }
#'
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr tibble bind_rows mutate select
#' @importFrom lubridate as_datetime
#' @importFrom utils write.csv
#'
#' @export

parseJsonSpec <- function(filepath) {

  raw <- fromJSON(filepath, simplifyVector = TRUE, simplifyDataFrame = FALSE)

  safe_get <- function(x, field, default = NA) {
    if (!is.null(x[[field]])) x[[field]] else default
  }

  # Write outputs alongside the source JSON (i.e. wherever the user's
  # working directory currently is) rather than a hardcoded package path.
  output_dir <- dirname(filepath)

  # ════════════════════════════════════════════════════════════════════════
  # 1. DATA tibble — from the top-level "data" column-vector object
  # ════════════════════════════════════════════════════════════════════════
  d <- raw$data

  if (is.null(d)) {
    Data <- tibble(
      Participant.ID   = character(),
      Session.ID        = numeric(),
      Alert.Times         = character(),
      Survey.Start          = as_datetime(character()),
      Survey.Date.Completed   = as_datetime(character()),
      Survey.Date.Submitted    = as_datetime(character()),
      Timezone                  = character(),
      Offset                      = numeric(),
      Network.Type                 = character(),
      App.Version                    = character(),
      OS                               = character(),
      Model                             = character(),
      User.Response                      = character(),
      Question.ID                         = character(),
      External.ID                           = character()
    )
  } else {
    n <- max(sapply(d[!sapply(d, is.null)], length))

    pad <- function(x, n, default = NA) {
      if (is.null(x) || length(x) == 0) rep(default, n) else unlist(x)
    }

    alert_times <- if (is.null(d$Alert.Times) || length(d$Alert.Times) == 0) {
      rep(NA_character_, n)
    } else {
      vapply(d$Alert.Times, function(times) paste(unlist(times), collapse = ";"), character(1))
    }

    Data <- tibble(
      Participant.ID   = pad(d$Participant.ID,       n, NA_character_),
      Session.ID        = pad(d$Session.ID,            n, NA_real_),
      Alert.Times         = alert_times,
      Survey.Start          = as_datetime(pad(d$Survey.Start,          n, NA_character_)),
      Survey.Date.Completed   = as_datetime(pad(d$Survey.Date.Completed, n, NA_character_)),
      Survey.Date.Submitted    = as_datetime(pad(d$Survey.Date.Submitted, n, NA_character_)),
      Timezone                  = pad(d$Timezone,                n, NA_character_),
      Offset                      = pad(d$Offset,                  n, NA_real_),
      Network.Type                 = pad(d$Network.Type,             n, NA_character_),
      App.Version                    = pad(d$App.Version,               n, NA_character_),
      OS                               = pad(d$OS,                        n, NA_character_),
      Model                             = pad(d$Model,                     n, NA_character_),
      User.Response                      = pad(d$User.Response,             n, NA_character_),
      Question.ID                         = pad(d$Question.ID,               n, NA_character_),
      External.ID                           = pad(d$External.ID,               n, NA_character_)
    )
  }

  # ════════════════════════════════════════════════════════════════════════
  # 2. BLOCKMAP + 3. RESPONSEKEY — iterate surveys[] -> questions[]
  # ════════════════════════════════════════════════════════════════════════
  surveys <- raw$surveys

  blockMap_rows    <- list()
  responseKey_rows <- list()

  for (sur in surveys) {

    survey_short <- safe_get(sur, "Survey.Name",     NA_character_)
    survey_long  <- safe_get(sur, "Survey.LongName", NA_character_)
    questions    <- sur$questions

    for (q in questions) {
      ci <- q$Conditional.Info
      rk <- q$responseKey

      # Group Conditional.Child.Mappings by child Item.ID, in first-seen
      # order, so Conditional.Child.Item.ID and Definitions line up
      # positionally: each ';'-separated slot is one child, and within a
      # slot the response labels that route to it are '|'-joined.
      # e.g. Definitions:                "Recovery Community Center (RCC); Home|Friend's house..."
      #      Conditional.Child.Item.ID:  "5745; 5746"
      child_mappings <- safe_get(ci, "Conditional.Child.Mappings", NULL)

      if (is.null(child_mappings) || length(child_mappings) == 0) {
        child_ids_str   <- NA_character_
        definitions_str <- NA_character_
      } else {
        map_child_id <- vapply(child_mappings, function(m) as.character(safe_get(m, "Conditional.Child.Item.ID", NA_character_)), character(1))
        map_def      <- vapply(child_mappings, function(m) as.character(safe_get(m, "Definition", NA_character_)), character(1))

        ordered_ids <- unique(map_child_id)
        grouped_defs <- vapply(ordered_ids, function(id) {
          paste(map_def[map_child_id == id], collapse = "|")
        }, character(1))

        child_ids_str   <- paste(ordered_ids, collapse = "; ")
        definitions_str <- paste(grouped_defs, collapse = "; ")
      }

      blockMap_rows[[length(blockMap_rows) + 1]] <- tibble(
        Survey                     = survey_short,
        Survey.LongName            = survey_long,
        Item.ID                    = safe_get(q, "Item.ID", NA_character_),
        Item.Type                  = safe_get(q, "Item.Type", NA_character_),
        Parent                     = safe_get(q, "Parent", NA_character_),
        Block                      = safe_get(q, "Parent", NA_character_),
        Sub.block                  = NA_character_,
        Question.ID                = safe_get(q, "Question.ID", NA_character_),
        Question.Text              = safe_get(q, "Question.Text", NA_character_),
        Question.Type              = NA_real_,
        Conditional.Child.Item.ID  = child_ids_str,
        Conditional.Fail.Item.ID   = as.character(safe_get(ci, "Conditional.Fail.Item.ID",   NA_character_)),
        Conditional.Threshold      = safe_get(ci,  "Conditional.Threshold",      NA_character_),
        Conditional.Type           = as.character(safe_get(ci, "Conditional.Type",           NA_character_)),
        Conditional.Master.Item.ID = as.character(safe_get(ci, "Conditional.Master.Item.ID", NA_character_)),
        Question.Type.Display.Name = safe_get(q, "Question.Type.Display.Name", NA_character_),
        Result.Type                = safe_get(q, "Data.Type", NA_character_),
        Multi.Conditional          = safe_get(ci, "Multi.Conditional", NA),
        Conditional.Limit          = safe_get(ci, "Conditional.Limit", NA_real_),
        Definitions                = definitions_str,
        Exit.Row                   = NA
      )

      if (!is.null(rk) && length(rk) > 0) {
        rk_rows <- bind_rows(lapply(rk, as.data.frame)) %>%
          mutate(
            survey   = survey_short,
            question = safe_get(q, "Question.ID", NA_character_),
            type     = "Response",
            value    = as.numeric(value)
          ) %>%
          select(survey, question, type, value, definition)

        responseKey_rows[[length(responseKey_rows) + 1]] <- rk_rows
      }
    }
  }

  blockMap <- if (length(blockMap_rows) > 0) bind_rows(blockMap_rows) else tibble(
    Survey                     = character(),
    Survey.LongName            = character(),
    Item.ID                    = character(),
    Item.Type                  = character(),
    Parent                     = character(),
    Block                      = character(),
    Sub.block                  = character(),
    Question.ID                = character(),
    Question.Text              = character(),
    Question.Type              = numeric(),
    Conditional.Child.Item.ID  = character(),
    Conditional.Fail.Item.ID   = character(),
    Conditional.Threshold      = character(),
    Conditional.Type           = character(),
    Conditional.Master.Item.ID = character(),
    Question.Type.Display.Name = character(),
    Result.Type                = character(),
    Multi.Conditional           = logical(),
    Conditional.Limit           = numeric(),
    Definitions                 = character(),
    Exit.Row                    = logical()
  )

  responseKey <- if (length(responseKey_rows) > 0) bind_rows(responseKey_rows) else tibble(
    survey     = character(),
    question   = character(),
    type       = character(),
    value      = numeric(),
    definition = character()
  )

  if (all(is.na(blockMap$Survey) | blockMap$Survey == "")) {
    blockMap$Survey <- blockMap$Survey.LongName
  }

  write.csv(blockMap,     file.path(output_dir, "blockMap.csv"))
  write.csv(responseKey,  file.path(output_dir, "responseKey.csv"))
  write.csv(Data,         file.path(output_dir, "Data.csv"))

  invisible(NULL)
}
