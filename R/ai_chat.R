#' System prompt for the in-app Wear-IT assistant
#' @keywords internal
wearit_system_prompt <- function(model_label) {
  paste0(
    "You are the Wear-IT Study Assistant inside the WearItReadR app. ",
    "You help researchers design, modify, and document Wear-IT studies.\n\n",
    "You are running as: ", model_label, ". Use this as the `model` argument ",
    "whenever you call save_study.\n\n",
    "TO CREATE A NEW STUDY:\n",
    "1. Call get_study_schema.\n",
    "2. Call search_item_repository for relevant validated scales (try a few keywords).\n",
    "3. Write the complete study JSON and call save_study with mode = 'generate'.\n",
    "4. If save_study reports errors, fix them and call save_study again (up to 5 tries).\n\n",
    "TO MODIFY THE CURRENT STUDY:\n",
    "1. Call get_current_study and get_study_schema.\n",
    "2. Apply the change and send the WHOLE study to save_study with mode = 'modify'.\n\n",
    "OTHER TOOLS: pull_data, generate_codebook, generate_data_dictionary, survey_flowchart. ",
    "Use them when the user asks.\n\n",
    "Always pass the user's own words as the `prompt` argument to save_study. ",
    "Keep replies short and friendly. After saving, briefly summarize what the study ",
    "contains (surveys, scales, schedule). Never show raw JSON unless asked."
  )
}

#' Help text shown when the user types "help"
#' @keywords internal
wearit_help_text <- function(dir) {
  has_study <- file.exists(file.path(dir, "study_output.json"))
  paste0(
    "Here's what I can do:\n\n",
    "- Create a study: \"Create a 2-week study on stress in college students, 3 surveys a day\"\n",
    "- Change your study: \"Add demographic questions for age and gender\"\n",
    "- Pull data: \"Pull data for study 123 using my saved key my_study\"\n",
    "- Build outputs: \"Make the codebook\", \"Make the data dictionary\", \"Show the flowchart for the Morning survey\"\n",
    "- Ask questions: \"What scales do you have for anxiety?\"\n\n",
    if (has_study) "Status: a study exists in your folder, so you can modify it."
    else "Status: no study yet. Ask me to create one."
  )
}

# Ask an OpenAI-compatible endpoint which models it has; pick a chat model
discover_model <- function(base_url, api_key) {
  req <- httr2::request(paste0(sub("/+$", "", base_url), "/models"))
  req <- httr2::req_timeout(req, 15)
  if (nzchar(api_key)) {
    req <- httr2::req_auth_bearer_token(req, api_key)
    req <- httr2::req_headers(req, `api-key` = api_key)  # Azure-style auth
  }
  res <- tryCatch(httr2::req_perform(req), error = function(e) NULL)
  if (is.null(res)) return(NULL)

  data <- httr2::resp_body_json(res)$data
  ids  <- vapply(data, function(m) as.character(m$id), "")
  ids  <- ids[!grepl("embed|whisper|tts|dall-e|image|moderation|audio|rerank",
                     ids, ignore.case = TRUE)]
  if (length(ids) == 0) NULL else ids[1]
}

# Work out which provider a URL / key belongs to
detect_provider <- function(url, api_key) {
  u <- tolower(url)
  if (grepl("api\\.openai\\.com", u)) return("openai")
  if (grepl("api\\.anthropic\\.com", u)) return("anthropic")
  if (grepl("generativelanguage\\.googleapis\\.com", u)) return("gemini")
  if (nzchar(u)) return("compatible")

  # No URL: guess from the key format
  if (startsWith(api_key, "sk-ant-")) return("anthropic")
  if (startsWith(api_key, "sk-"))     return("openai")
  if (startsWith(api_key, "AIza"))    return("gemini")
  stop("Please enter your AI URL.")
}

#' Create an AI chat connected to the Wear-IT tools
#'
#' @param url The AI's URL (any OpenAI-compatible endpoint, or OpenAI /
#'   Anthropic / Google). Can be blank for those three if the key is given.
#' @param api_key The user's API key.
#' @param dir Study working directory.
#' @param on_tool Optional callback, called with each tool name the AI uses.
#' @return An ellmer Chat object.
#' @export
wearit_chat <- function(url = "", api_key = "", dir = getwd(), on_tool = NULL) {
  url      <- trimws(url)
  api_key  <- trimws(api_key)
  provider <- detect_provider(url, api_key)
  creds    <- if (nzchar(api_key)) function() api_key else NULL

  # Optional override for power users; normal users never touch this
  model <- Sys.getenv("WEARIT_AI_MODEL", "")
  model <- if (nzchar(model)) model else NULL

  if (provider == "compatible" && is.null(model)) {
    model <- discover_model(url, api_key)
    if (is.null(model)) {
      stop("Couldn't find a model at that URL. Check the URL and API key.")
    }
  }

  label <- paste0(
    switch(provider, openai = "OpenAI", anthropic = "Anthropic",
           gemini = "Google Gemini", compatible = "AI endpoint"),
    if (!is.null(model)) paste0(" / ", model) else ""
  )
  sys <- wearit_system_prompt(label)

  chat <- switch(
    provider,
    openai     = ellmer::chat_openai(system_prompt = sys, model = model,
                                     credentials = creds),
    anthropic  = ellmer::chat_anthropic(system_prompt = sys, model = model,
                                        credentials = creds),
    gemini     = ellmer::chat_google_gemini(system_prompt = sys, model = model,
                                            credentials = creds),
    compatible = ellmer::chat_openai_compatible(base_url = url, system_prompt = sys,
                                                model = model, credentials = creds)
  )

  chat$register_tools(wearit_tools(dir, public = FALSE))

  if (is.function(on_tool)) {
    tryCatch(
      chat$on_tool_request(function(request) on_tool(request@name)),
      error = function(e) NULL
    )
  }

  chat
}
