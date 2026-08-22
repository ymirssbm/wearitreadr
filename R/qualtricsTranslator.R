library(httr)
library(jsonlite)
library(jsonvalidate)

#' Translate Qualtrics Survey to Wear-IT Study Spec (schema v0.1.0)
#'
#' @param survey_id Qualtrics survey ID (e.g. "SV_xxxxxxxxxxxxxxx")
#' @param api_key Qualtrics API token
#' @param data_center Qualtrics data center ID (e.g. "iad1")
#' @param schema_path Path to study.json schema file
#' @param study_meta Optional list with Study.Name, authors, funding, abstract
#' @return list(spec, spec_json, valid, errors)
#' @export
qualtrics_to_wearit <- function(survey_id,
                                api_key,
                                data_center,
                                schema_path = "inst/schema/0.1.0/study.json",
                                study_meta = list()) {

  `%||%` <- function(a, b) if (!is.null(a) && !(length(a) == 1 && is.na(a))) a else b

  base_url <- paste0("https://", data_center, ".qualtrics.com")

  #---------------------------
  # Step 1: Fetch survey
  #---------------------------
  message("Fetching survey from Qualtrics...")

  response <- GET(
    url      = paste0(base_url, "/API/v3/surveys/", survey_id),
    add_headers("X-API-TOKEN" = api_key)
  )

  if (http_error(response)) {
    stop("Qualtrics API error: ", content(response, as = "text"))
  }

  survey <- fromJSON(content(response, as = "text"), flatten = TRUE)$result

  #---------------------------
  # Step 2: Helper functions
  #---------------------------

  # Map Qualtrics DisplayLogic operators -> Wear-IT Conditional.Type codes
  map_operator <- function(op) {
    if (is.null(op) || length(op) == 0 || is.na(op)) return(NULL)
    mapping <- c(
      "Selected"           = "1",
      "EqualTo"            = "1",
      "NotSelected"        = "6",
      "NotEqualTo"         = "6",
      "LessThanOrEqual"    = "2",
      "GreaterThanOrEqual" = "3",
      "LessThan"           = "4",
      "GreaterThan"        = "5"
    )
    val <- unname(mapping[op])
    if (is.na(val)) NULL else val
  }

  # Map Qualtrics question types to Wear-IT display types
  map_question_type <- function(q_type) {
    out <- switch(q_type,
                  "MC"     = "Multiple Choice",
                  "TE"     = "Free Response",
                  "Slider" = "Slider",
                  "Matrix" = "Multiple Slider",
                  "CS"     = "Multiple Select",
                  "DB"     = "Informational Fullscreen",
                  "TP"     = "Time Picker",
                  NULL)
    out %||% q_type
  }

  # Data.Type is restricted by schema to integer/character/numeric/null
  map_data_type <- function(q_type) {
    switch(q_type,
           "Slider" = "numeric",
           "TE"     = "character",
           "MC"     = "integer",
           "CS"     = "integer",
           "Matrix" = "integer",
           NULL)
  }

  sanitize <- function(text) {
    if (is.null(text) || length(text) == 0 || is.na(text)) return(NULL)
    text <- gsub("<.*?>", "", text)   # strip HTML
    trimws(text)
  }

  # Pull the *master*-question display logic off a child question.
  # NOTE: Qualtrics DisplayLogic is only lightly structured here (single
  # top-level AND/OR group, first condition only) — same caveat as before.
  extract_master_logic <- function(q) {
    out <- list(Conditional.Master.Item.ID = NULL,
                Conditional.Threshold      = NULL,
                Conditional.Type           = NULL)

    if (!is.null(q$DisplayLogic) && length(q$DisplayLogic) > 0) {
      dl <- q$DisplayLogic
      if (!is.null(dl$`0`$`0`)) {
        cond <- dl$`0`$`0`
        master_qid <- cond$QuestionID %||% cond$QuestionIDFromLocator
        out$Conditional.Master.Item.ID <- if (!is.null(master_qid)) paste0("Item ", master_qid) else NULL
        out$Conditional.Type      <- map_operator(cond$Operator)
        out$Conditional.Threshold <- sanitize(cond$Description) %||%
          (if (!is.null(cond$Value)) as.character(cond$Value) else NULL)
      }
    }
    out
  }

  extract_response_key <- function(q) {
    if (is.null(q$choices)) return(list())
    lapply(names(q$choices), function(choice_id) {
      list(
        value      = as.character(q$choices[[choice_id]]$recode %||% choice_id),
        definition = sanitize(q$choices[[choice_id]]$choiceText) %||% ""
      )
    })
  }

  #---------------------------
  # Step 3: Build items (blocks + questions)
  #---------------------------
  message("Building items...")

  blocks    <- survey$blocks
  questions <- survey$questions
  survey_name <- sanitize(survey$name) %||% survey_id

  all_items <- list()

  # qid -> list of {Conditional.Child.Item.ID, Definition} to attach to that
  # question once it's been identified as someone else's master
  child_mappings_by_master <- list()

  for (block_id in names(blocks)) {
    block <- blocks[[block_id]]
    block_item_id <- paste0("Item ", block_id)

    # Blocks: no Question.Text / Data.Type / responseKey keys at all —
    # the schema forbids their *presence* (even as null) on Block items.
    all_items[[length(all_items) + 1]] <- list(
      Item.ID                    = block_item_id,
      Item.Type                  = "Block",
      Parent                     = NULL,
      Question.ID                = block_id,
      Question.Type.Display.Name = "Block"
    )

    elements <- block$elements
    if (is.null(elements)) next

    for (j in seq_len(nrow(elements))) {
      el <- elements[j, ]
      if (is.null(el$type) || el$type != "Question") next

      qid <- el$questionId
      q   <- questions[[qid]]
      if (is.null(q)) next

      item_id <- paste0("Item ", qid)

      q_type_raw    <- q$questionType$type %||% "Unknown"
      q_type_mapped <- map_question_type(q_type_raw)
      data_type     <- map_data_type(q_type_raw)

      master_logic <- extract_master_logic(q)
      if (!is.null(master_logic$Conditional.Master.Item.ID)) {
        master_id <- master_logic$Conditional.Master.Item.ID
        child_mappings_by_master[[master_id]] <- c(
          child_mappings_by_master[[master_id]],
          list(list(
            Conditional.Child.Item.ID = item_id,
            Definition = master_logic$Conditional.Threshold %||% ""
          ))
        )
      }

      all_items[[length(all_items) + 1]] <- list(
        Item.ID                    = item_id,
        Item.Type                  = "Question",
        Parent                     = block_item_id,
        Question.ID                = qid,
        Question.Text              = sanitize(q$questionText) %||% "",
        Question.Type.Display.Name = q_type_mapped,
        Data.Type                  = data_type,
        responseKey                = extract_response_key(q),
        Conditional.Info = list(
          Conditional.Master.Item.ID = master_logic$Conditional.Master.Item.ID,
          Conditional.Threshold      = master_logic$Conditional.Threshold,
          Conditional.Type           = master_logic$Conditional.Type,
          Conditional.Fail.Item.ID   = NULL,
          Conditional.Child.Mappings = NULL
        )
      )
    }
  }

  # Second pass: attach Conditional.Child.Mappings to whichever item is
  # referenced as someone else's Conditional.Master.Item.ID
  for (i in seq_along(all_items)) {
    it <- all_items[[i]]
    if (identical(it$Item.Type, "Question")) {
      mappings <- child_mappings_by_master[[it$Item.ID]]
      if (!is.null(mappings)) {
        all_items[[i]]$Conditional.Info$Conditional.Child.Mappings <- mappings
      }
    }
  }

  questions_only <- Filter(function(x) identical(x$Item.Type, "Question"), all_items)

  #---------------------------
  # Step 4: Build blockMap
  #---------------------------
  message("Building blockMap...")

  block_map <- lapply(all_items, function(it) {
    list(
      Survey.Name = survey_name,
      Item.ID     = it$Item.ID,
      Item.Type   = it$Item.Type,
      Parent      = it$Parent
    )
  })

  #---------------------------
  # Step 5: Assemble spec
  #---------------------------
  message("Assembling study spec...")

  study_spec <- list(
    Study.Name = study_meta$Study.Name %||% survey_name,
    authors    = study_meta$authors    %||% "",
    funding    = study_meta$funding    %||% "",
    abstract   = study_meta$abstract   %||% "",
    schedules  = list(),   # Qualtrics gives us no timing/scheduling info
    surveys    = list(
      list(
        Survey.LongName = survey_name,
        Survey.Name     = survey_name,
        questions       = questions_only
      )
    ),
    blockMap = block_map
  )

  #---------------------------
  # Step 6: Validate
  #---------------------------
  schema_obj <- read_json(schema_path)

  spec_json <- toJSON(
    study_spec,
    auto_unbox = TRUE,
    null = "null",
    pretty = TRUE
  )

  schema_json <- toJSON(
    schema_obj,
    auto_unbox = TRUE,
    null = "null",
    pretty = TRUE
  )

  message("Validating against Wear-IT schema...")

  validation <- jsonvalidate::json_validate(
    json = spec_json,
    schema = schema_json,
    engine = "ajv",
    verbose = TRUE
  )

  if (!validation) {
    errors <- attr(validation, "errors")
    message("Schema validation failed with the following errors:")
    print(errors)
  }

  #---------------------------
  # Step 7: Return
  #---------------------------
  list(
    spec      = study_spec,
    spec_json = spec_json,
    valid     = as.logical(validation),
    errors    = if (!validation) attr(validation, "errors") else NULL
  )
}

# result <- qualtrics_to_wearit(
#   survey_id   = "SV_3JVDH61TNOr2pJI",
#   api_key     = api_key,
#   data_center = "yul1",
#   schema_path = "inst/schema/0.1.0/study.json",
#   study_meta  = list(
#     Study.Name = "My Study",
#     authors    = "Jane Smith, John Doe",
#     funding    = "NIH Grant R01DA012345",
#     abstract   = "Study abstract here"
#   )
# )
#
# cat("Valid:", result$valid, "\n")
# print(result$errors)
# write(result$spec_json, "my_study_spec.json")
