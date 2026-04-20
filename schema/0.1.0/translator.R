library(httr)
library(jsonlite)
library(jsonvalidate)

#' Translate Qualtrics Survey to Wear-IT Study Spec
#'
#' @param survey_id Qualtrics survey ID (e.g. "SV_xxxxxxxxxxxxxxx")
#' @param api_key Qualtrics API token
#' @param data_center Qualtrics data center ID (e.g. "iad1")
#' @param schema_path Path to study.json schema file
#' @param study_meta Optional list with Study.Name, authors, funding, abstract
#' @return Validated Wear-IT study spec as a list
#' @export
qualtrics_to_wearit <- function(survey_id,
                                api_key,
                                data_center,
                                schema_path,
                                study_meta = list()) {

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

  # Map Qualtrics operators to Wear-IT Conditional.Type
  map_operator <- function(op) {
    if (is.null(op) || is.na(op)) return(NULL)
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
    unname(mapping[op])
  }

  # Map Qualtrics question types to Wear-IT display types
  map_question_type <- function(q_type) {
    switch(q_type,
           "MC"     = "Multiple Choice",
           "TE"     = "Free Response",
           "Slider" = "Slider",
           "Matrix" = "Multiple Slider",
           "CS"     = "Multiple Select",
           "DB"     = "Informational Fullscreen",
           "TP"     = "Time Picker",
           NULL
    )
  }

  # Sanitize text for use in spec
  sanitize <- function(text) {
    if (is.null(text) || is.na(text)) return(NULL)
    text <- gsub("<.*?>", "", text)   # strip HTML
    trimws(text)
  }

  # Extract display logic from a question
  extract_logic <- function(q) {
    logic <- list(
      Conditional.Type           = NULL,
      Conditional.Threshold      = NULL,
      Conditional.Child.Item.ID  = NULL,
      Conditional.Fail.Item.ID   = NULL,
      Conditional.Master.Item.ID = NULL
    )

    if (!is.null(q$DisplayLogic) && length(q$DisplayLogic) > 0) {
      dl <- q$DisplayLogic
      if (!is.null(dl$`0`$`0`)) {
        cond <- dl$`0`$`0`
        logic$Conditional.Type             <- map_operator(cond$Operator)
        logic$Conditional.Threshold        <- as.character(cond$Value)
        logic$Conditional.Master.Item.ID   <- cond$QuestionID
      }
    }
    logic
  }

  # Build responseKey for a question
  extract_response_key <- function(q) {
    if (is.null(q$Choices)) return(NULL)

    lapply(names(q$Choices), function(choice_id) {
      list(
        value      = choice_id,
        definition = sanitize(q$Choices[[choice_id]]$Display)
      )
    })
  }

  #---------------------------
  # Step 3: Build blockMap
  #---------------------------
  message("Building blockMap...")

  blocks    <- survey$blocks
  questions <- survey$questions

  all_questions <- list()

  for (block_id in names(blocks)) {
    block <- blocks[[block_id]]

    block_item_id <- paste0("Item ", block_id)
    all_questions[[length(all_questions) + 1]] <- list(
      Item.ID                    = block_item_id,
      Item.Type                  = "Block",
      Parent                     = NULL,
      Question.ID                = NULL,
      Question.Text              = sanitize(block$description),
      Question.Type.Display.Name = NULL,
      Data.Type                  = NULL,
      responseKey                = NULL,
      Conditional.Info           = NULL
    )

    elements <- block$elements
    if (is.null(elements)) next

    for (j in seq_len(nrow(elements))) {
      el <- elements[j, ]
      if (is.null(el$type) || el$type != "Question") next

      qid <- el$questionId
      q   <- questions[[qid]]
      if (is.null(q)) next

      # Extract display logic
      logic <- extract_logic(q)

      # Extract response key
      response_key <- list()  # default to empty array

      if (!is.null(q$choices)) {
        response_key <- lapply(names(q$choices), function(choice_id) {
          list(
            value      = q$choices[[choice_id]]$recode,
            definition = sanitize(q$choices[[choice_id]]$choiceText)
          )
        })
      }

      # Map question type to Wear-IT display type
      q_type_raw    <- q$questionType$type %||% "Unknown"
      q_type_mapped <- map_question_type(q_type_raw) %||% q_type_raw

      # Data type mapping
      data_type <- switch(q_type_raw,
                          "Slider" = "numeric",
                          "TE"     = "character",
                          "MC"     = "integer",
                          "Matrix" = "integer",
                          NULL
      )

      all_questions[[length(all_questions) + 1]] <- list(
        Item.ID                    = paste0("Item ", qid),
        Item.Type                  = "Question",
        Parent                     = block_item_id,
        Question.ID                = qid,
        Question.Text              = sanitize(q$questionText),
        Question.Type.Display.Name = q_type_mapped,
        Data.Type                  = data_type,
        responseKey                = response_key,
        Conditional.Info           = list(
          Conditional.Type           = logic$Conditional.Type,
          Conditional.Threshold      = logic$Conditional.Threshold,
          Conditional.Child.Item.ID  = logic$Conditional.Child.Item.ID,
          Conditional.Fail.Item.ID   = logic$Conditional.Fail.Item.ID,
          Conditional.Master.Item.ID = logic$Conditional.Master.Item.ID
        )
      )
    }
  }

  #---------------------------
  # Step 4: Assemble spec
  #---------------------------
  message("Assembling study spec...")

  # Get just question entries, not block entries
  questions_only <- Filter(function(x) x$Item.Type == "Question", all_questions)

  study_spec <- list(
    Study.Name = study_meta$Study.Name %||% sanitize(survey$name),
    authors    = study_meta$authors    %||% "",
    funding    = study_meta$funding    %||% "",
    abstract   = study_meta$abstract   %||% "",
    burst = list(
      burstID = 1L,
      survey  = list(
        Survey.LongName  = sanitize(survey$name),
        Survey.ShortName = "",
        question         = questions_only  # full array, not just first element
      )
    ),
    blockMap = list()
  )

  #---------------------------
  # Step 5: Validate
  #---------------------------
  library(jsonlite)

  # Load schema as a parsed object
  schema_obj <- read_json(schema_path)

  # Your spec JSON
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
  # Step 6: Return
  #---------------------------
  list(
    spec      = study_spec,
    spec_json = spec_json,
    valid     = as.logical(validation),
    errors    = if (!validation) attr(validation, "errors") else NULL
  )
}

# Null coalescing operator
`%||%` <- function(a, b) if (!is.null(a)) a else b


result <- qualtrics_to_wearit(
  survey_id   = "SV_3JVDH61TNOr2pJI",
  api_key     = api_key,
  data_center = "yul1",
  schema_path = "study.json",
  study_meta  = list(
    Study.Name = "My Study",
    authors    = "Jane Smith, John Doe",
    funding    = "NIH Grant R01DA012345",
    abstract   = "Study abstract here"
  )
)


cat("Valid:", result$valid, "\n")
cat("Errors:\n")
print(result$errors)

# Check if it validated
result$valid

# See any validation errors
#result$errors

# View the spec as a list
#result$spec

# Save the JSON to a file
write(result$spec_json, "my_study_spec.json")
