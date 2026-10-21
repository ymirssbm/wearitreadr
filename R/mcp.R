# =====================================================================
# WearItReadR <-> AI tools (MCP)
#
# Desktop apps that use a config file : wearitreadr_mcp()        (stdio)
# Desktop apps that take a URL        : wearitreadr_connect()$local_url
# Web apps (ChatGPT, claude.ai, ...)  : wearitreadr_connect()$public_url
# =====================================================================


#' Validate and save a study JSON
#'
#' Shared by the MCP save_study tool and the in-app copy/paste flow.
#'
#' @param study_json Study JSON as text (code fences / chatter are stripped).
#' @param prompt The user's request that produced this study or change.
#' @param model Name of the AI that wrote it (for AI disclosure).
#' @param mode "generate" or "modify".
#' @param dir Working directory holding study_output.json.
#' @return list(ok = TRUE/FALSE, message = chr)
#' @export
save_study_json <- function(study_json, prompt, model = "Unknown AI",
                            mode = c("generate", "modify"), dir = getwd()) {
  mode <- match.arg(mode)
  pkg_dir     <- system.file(package = "WearItReadR")
  schema_file <- file.path(pkg_dir, "schema", "0.1.0", "study.json")
  study_file  <- file.path(dir, "study_output.json")

  # Chatbots often wrap JSON in ``` fences or add text around it
  txt <- trimws(study_json)
  txt <- sub("^```(json)?\\s*", "", txt)
  txt <- sub("\\s*```$", "", txt)
  start <- regexpr("\\{", txt)
  if (start < 0) {
    return(list(ok = FALSE, message = "No JSON object found."))
  }
  txt <- substring(txt, start, max(gregexpr("\\}", txt)[[1]]))

  parsed <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE),
                     error = function(e) NULL)
  if (is.null(parsed)) {
    return(list(ok = FALSE, message = "Not valid JSON (it may be cut off)."))
  }

  res <- jsonvalidate::json_validate(txt, schema_file, engine = "ajv",
                                     verbose = TRUE, error = FALSE)
  if (!isTRUE(res)) {
    errs <- attr(res, "errors")
    msg <- paste(sprintf("%s: %s", errs$instancePath, errs$message),
                 collapse = "\n")
    return(list(ok = FALSE, message = msg))
  }

  # AI disclosure bookkeeping, done deterministically (same as the Python)
  prior <- if (mode == "modify" && file.exists(study_file)) {
    jsonlite::read_json(study_file, simplifyVector = FALSE)[["AI.Information"]]
  } else NULL

  if (!is.null(prior)) {
    parsed[["AI.Information"]] <- list(
      AI.Disclosure = c(prior$AI.Disclosure,
                        list(list(Characteristic = "Modification", Model = model))),
      AI.Generation.Prompt = prior$AI.Generation.Prompt,
      AI.Modification.Prompts = c(prior$AI.Modification.Prompts, list(prompt))
    )
  } else {
    parsed[["AI.Information"]] <- list(
      AI.Disclosure = list(list(Characteristic = "All", Model = model)),
      AI.Generation.Prompt = prompt,
      AI.Modification.Prompts = list()
    )
  }

  jsonlite::write_json(parsed, study_file, auto_unbox = TRUE,
                       pretty = TRUE, null = "null")
  utils::capture.output(parseJsonSpec(study_file))
  list(ok = TRUE, message = paste("Saved to", study_file))
}


#' WearItReadR tools for AI assistants
#'
#' @param dir Working directory where study files live.
#' @param public If TRUE, tools that use the local keyring (pull_data) are
#'   left out, because the server is reachable from the internet.
#' @return A list of ellmer tool definitions.
#' @export
wearit_tools <- function(dir = getwd(), public = FALSE) {
  pkg_dir     <- system.file(package = "WearItReadR")
  schema_file <- file.path(pkg_dir, "schema", "0.1.0", "study.json")
  item_file   <- file.path(pkg_dir, "Codebook_RMD", "Data", "itemRepository.csv")
  study_file  <- file.path(dir, "study_output.json")

  # In stdio mode, anything printed to stdout corrupts the MCP connection.
  # Your functions print() progress, so every tool body runs through this.
  quiet <- function(expr) {
    utils::capture.output(val <- expr)
    val
  }

  servers <- c(
    "wearables-survey"     = "https://wearables.vmhost.psu.edu/wearables-survey/api",
    "wearables-survey_sdb" = "https://wearables.vmhost.psu.edu/wearables-survey_sdb/api"
  )

  tools <- list(
    # ---------- Study design ----------
    get_study_schema = ellmer::tool(
      function() paste(readLines(schema_file, warn = FALSE), collapse = "\n"),
      name = "get_study_schema",
      description = paste(
        "Return the Wear-IT study JSON schema (v0.1.0). Read this before writing",
        "or modifying a study. Use 'Item.Type' (not 'Type'); 'Conditional.Type'",
        "must be '1'-'6' or null; do not invent field names."
      )
    ),

    search_item_repository = ellmer::tool(
      function(query, max_results = 25) {
        repo <- utils::read.csv(item_file, stringsAsFactors = FALSE)
        text <- do.call(paste, c(repo, sep = " "))
        hits <- repo[grepl(query, text, ignore.case = TRUE), , drop = FALSE]
        if (nrow(hits) == 0) return("No matching items. You may write new items.")
        jsonlite::toJSON(utils::head(hits, max_results), pretty = TRUE)
      },
      name = "search_item_repository",
      description = paste(
        "Search the repository of validated scales/items (e.g. 'PHQ', 'anxiety',",
        "'sleep'). Prefer these over inventing new items."
      ),
      arguments = list(
        query = ellmer::type_string("Keyword or regex to search for."),
        max_results = ellmer::type_integer("Max rows to return (default 25).",
                                           required = FALSE)
      )
    ),

    get_current_study = ellmer::tool(
      function() {
        if (!file.exists(study_file)) return("No study exists yet in this directory.")
        paste(readLines(study_file, warn = FALSE), collapse = "\n")
      },
      name = "get_current_study",
      description = "Return the current study_output.json, if one exists. Read it before modifying."
    ),

    save_study = ellmer::tool(
      function(study_json, prompt, model, mode = "generate") {
        res <- quiet(save_study_json(study_json, prompt, model, mode, dir))
        if (res$ok) {
          paste("Valid.", res$message)
        } else {
          paste0("INVALID - not saved. Fix these and call save_study again:\n",
                 res$message)
        }
      },
      name = "save_study",
      description = paste(
        "Validate a full study JSON against the schema and save it. If invalid,",
        "returns the errors so you can fix and retry. Always send the WHOLE study."
      ),
      arguments = list(
        study_json = ellmer::type_string("Complete study JSON object (not a list at top level)."),
        prompt = ellmer::type_string("The user's request that produced this study/change."),
        model = ellmer::type_string("Name of the AI model you are (for AI disclosure)."),
        mode = ellmer::type_enum(c("generate", "modify"), "New study or modification.",
                                 required = FALSE)
      )
    ),

    # ---------- Data + outputs ----------
    pull_data = ellmer::tool(
      function(study_id, keyring_key, server = "wearables-survey") {
        token <- keyring::key_get(keyring_key)  # token never passes through the AI
        quiet(saveData(study_ID = study_id, apiToken = token,
                       base_URL = servers[[server]], pull = TRUE,
                       skip_readline = TRUE))
        paste("Data pulled into", dir)
      },
      name = "pull_data",
      description = "Pull study data from Wear-IT using an API token saved in the system keyring.",
      arguments = list(
        study_id = ellmer::type_string("Wear-IT study ID."),
        keyring_key = ellmer::type_string("Name of the keyring entry holding the API token."),
        server = ellmer::type_enum(names(servers), "Which Wear-IT server.",
                                   required = FALSE)
      )
    ),

    generate_codebook = ellmer::tool(
      function(title = "", authors = "", funding = "", abstract = "",
               summary = "", exclude = NULL) {

        # Question types available in this install of the package
        data_types <- sub("\\.Rmd$", "", list.files(
          file.path(pkg_dir, "Codebook_RMD", "DataTypes")))
        if (length(data_types) == 0) {
          data_types <- c("FreeResponse", "InformationalFullscreen", "MultipleChoice",
                          "MultipleSelect", "MultipleSlider", "Slider", "TimePicker",
                          "TimeScaleSlider", "Block", "EndBlock")
        }

        # Same structure as the Shiny options tree: parent = children
        tree <- list(
          "Title Page"        = c("Name of Study", "Authors", "Study Metadata",
                                  "Desired Graphic", "Funding"),
          "Abstract"          = character(),
          "Effective Summary" = character(),
          "Data Types"        = data_types,
          "Variable Pages"    = c("Histograms", "Missingness Page", "Descriptives",
                                  "Bar Plot", "Frequency Table", "Type of data",
                                  "Way question was delivered", "Screenshot",
                                  "Skip Logic"),
          "Include Data"      = character()
        )

        exclude <- tolower(unlist(exclude))

        options <- character()
        for (parent in names(tree)) {
          if (tolower(parent) %in% exclude) next          # whole branch unchecked
          kids <- tree[[parent]]
          kids <- kids[!tolower(kids) %in% exclude]
          if (length(tree[[parent]]) > 0 && length(kids) == 0) next  # all children unchecked
          options <- c(options, parent, kids)
        }
        options <- tolower(options)

        quiet(generateCodebook(
          shiny = TRUE,
          codebookChunkDisplayOptions = options,
          title    = if (nzchar(title)) title else "Study Codebook",
          authors  = authors,
          funding  = funding,
          abstract = abstract,
          summary  = summary,
          screenshotDir = file.path(dir, "screenshots"),
          output_file   = file.path(dir, "Codebook.html")
        ))

        excluded_msg <- if (length(exclude)) {
          paste0(" Excluded: ", paste(exclude, collapse = ", "), ".")
        } else " All sections included."
        paste0("Codebook written to ", file.path(dir, "Codebook.html"), ".", excluded_msg)
      },
      name = "generate_codebook",
      description = paste(
        "Generate the HTML codebook for the current study. Works before data is",
        "collected. By default EVERYTHING is included. Use `exclude` only when the",
        "user asks to leave something out (or it clearly doesn't apply).",
        "Excluding a section also excludes everything under it:",
        "'Title Page' (Name of Study, Authors, Study Metadata, Desired Graphic, Funding),",
        "'Variable Pages' (Histograms, Missingness Page, Descriptives, Bar Plot,",
        "Frequency Table, Type of data, Way question was delivered, Screenshot, Skip Logic),",
        "'Data Types' (question types; excluding a type removes those variables from",
        "the codebook, and excluding 'Data Types' removes ALL variables, so avoid that).",
        "'Include Data' controls whether participant data rows are included."
      ),
      arguments = list(
        title    = ellmer::type_string("Study title.", required = FALSE),
        authors  = ellmer::type_string("Authors.", required = FALSE),
        funding  = ellmer::type_string("Funding info.", required = FALSE),
        abstract = ellmer::type_string("Abstract.", required = FALSE),
        summary  = ellmer::type_string("Summary.", required = FALSE),
        exclude  = ellmer::type_array(
          ellmer::type_enum(c(
            "Title Page", "Name of Study", "Authors", "Study Metadata",
            "Desired Graphic", "Funding",
            "Abstract", "Effective Summary",
            "Data Types", "FreeResponse", "InformationalFullscreen",
            "MultipleChoice", "MultipleSelect", "MultipleSlider", "Slider",
            "TimePicker", "TimeScaleSlider", "Block", "EndBlock",
            "Variable Pages", "Histograms", "Missingness Page", "Descriptives",
            "Bar Plot", "Frequency Table", "Type of data",
            "Way question was delivered", "Screenshot", "Skip Logic",
            "Include Data"
          )),
          "Sections to leave out. Omit or leave empty to include everything.",
          required = FALSE
        )
      )
    ),

    generate_data_dictionary = ellmer::tool(
      function() {
        quiet(generateDataDictionary(shiny = TRUE))
        dd <- utils::read.csv(file.path(dir, "DataDictionary.csv"))
        jsonlite::toJSON(utils::head(dd, 50), pretty = TRUE)
      },
      name = "generate_data_dictionary",
      description = "Generate DataDictionary.csv from pulled data; returns the first 50 rows."
    ),

    survey_flowchart = ellmer::tool(
      function(survey = NULL) {
        bm <- utils::read.csv(file.path(dir, "blockMap.csv"))
        if (is.null(survey)) {
          return(paste(unique(stats::na.omit(bm$Survey)), collapse = "\n"))
        }
        rk <- utils::read.csv(file.path(dir, "responseKey.csv"))
        quiet(generateSurveyFlowchart(blockMap = bm, survey = survey,
                                      responseKey = rk, shiny = TRUE))
      },
      name = "survey_flowchart",
      description = paste(
        "With no survey: list surveys. With a survey name: return its",
        "skip-logic flowchart as Mermaid code."
      ),
      arguments = list(
        survey = ellmer::type_string("Survey name.", required = FALSE)
      )
    )
  )

  if (public) tools$pull_data <- NULL
  unname(tools)
}


#' Run WearItReadR as an MCP server (foreground)
#'
#' Use type = "stdio" in desktop apps that launch servers from a config file.
#' wearitreadr_connect() uses type = "http" in the background.
#'
#' @param dir Working directory for study files.
#' @param type "stdio" or "http".
#' @param port Port for http.
#' @param public Drop keyring-based tools (set automatically by wearitreadr_connect).
#' @export
wearitreadr_mcp <- function(dir = Sys.getenv("WEARIT_DIR", getwd()),
                            type = c("stdio", "http"), port = 8080,
                            public = FALSE) {
  type <- match.arg(type)

  # The server is started with WearItReadR::..., which loads but doesn't attach
  # the package. The codebook Rmd calls functions by bare name, so attach it.
  if (!"package:WearItReadR" %in% search()) {
    attachNamespace("WearItReadR")
  }

  setwd(dir)  # saveData() etc. read/write the working directory
  tools <- wearit_tools(dir, public = public)
  if (type == "stdio") {
    mcptools::mcp_server(tools = tools)
  } else {
    mcptools::mcp_server(tools = tools, type = "http", port = port)
  }
}

# ---------------------------------------------------------------------
# Internal: find or download cloudflared (free tunnel, no account needed)
# ---------------------------------------------------------------------
cloudflared_path <- function() {
  found <- Sys.which("cloudflared")
  if (nzchar(found)) return(unname(found))

  cache <- tools::R_user_dir("WearItReadR", "cache")
  dir.create(cache, recursive = TRUE, showWarnings = FALSE)

  sys  <- Sys.info()[["sysname"]]
  arm  <- grepl("arm|aarch", Sys.info()[["machine"]], ignore.case = TRUE)
  base <- "https://github.com/cloudflare/cloudflared/releases/latest/download/"

  if (sys == "Windows") {
    exe <- file.path(cache, "cloudflared.exe")
    if (!file.exists(exe)) {
      message("Downloading connection helper (one time only)...")
      utils::download.file(paste0(base, "cloudflared-windows-amd64.exe"),
                           exe, mode = "wb", quiet = TRUE)
    }
    return(exe)
  }

  exe <- file.path(cache, "cloudflared")
  if (!file.exists(exe)) {
    message("Downloading connection helper (one time only)...")
    if (sys == "Darwin") {
      tgz <- tempfile(fileext = ".tgz")
      utils::download.file(
        paste0(base, "cloudflared-darwin-", if (arm) "arm64" else "amd64", ".tgz"),
        tgz, mode = "wb", quiet = TRUE)
      utils::untar(tgz, exdir = cache)
    } else {
      utils::download.file(
        paste0(base, "cloudflared-linux-", if (arm) "arm64" else "amd64"),
        exe, mode = "wb", quiet = TRUE)
    }
    Sys.chmod(exe, "755")
  }
  exe
}

# Internal: wait until something is listening on a local port
wait_for_port <- function(port, timeout = 30) {
  deadline <- Sys.time() + timeout
  while (Sys.time() < deadline) {
    ok <- tryCatch({
      con <- suppressWarnings(socketConnection("127.0.0.1", port,
                                               open = "r+", timeout = 1))
      close(con)
      TRUE
    }, error = function(e) FALSE)
    if (ok) return(TRUE)
    Sys.sleep(0.5)
  }
  FALSE
}


#' Connect any AI tool (desktop or web) to WearItReadR
#'
#' Starts the MCP server in the background and, if public = TRUE, opens a
#' secure public HTTPS link so web-based AI tools (ChatGPT, claude.ai, etc.)
#' can reach it. Everything stops when you call $stop() or close R.
#'
#' @param dir Study working directory.
#' @param public Also create a public link for web AI tools.
#' @param port Local port.
#' @param mcp_path Endpoint path served by mcptools.
#' @return A list with local_url, public_url, is_running(), and stop().
#' @export
wearitreadr_connect <- function(dir = getwd(), public = TRUE, port = 8765,
                                mcp_path = "/mcp") {
  dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)

  server <- callr::r_bg(
    function(dir, port, public) {
      WearItReadR::wearitreadr_mcp(dir, type = "http", port = port,
                                   public = public)
    },
    args = list(dir = dir, port = port, public = public),
    supervise = TRUE
  )

  if (!wait_for_port(port)) {
    err <- tryCatch(server$read_all_error(), error = function(e) "")
    server$kill()
    stop("The AI connection couldn't start. ", err)
  }

  local_url  <- sprintf("http://localhost:%d%s", port, mcp_path)
  public_url <- NA_character_
  tunnel     <- NULL

  if (public) {
    log_file <- tempfile(fileext = ".log")
    tunnel <- processx::process$new(
      cloudflared_path(),
      c("tunnel", "--no-autoupdate", "--url", sprintf("http://localhost:%d", port)),
      stdout = log_file, stderr = "2>&1", supervise = TRUE
    )

    deadline <- Sys.time() + 45
    while (is.na(public_url) && Sys.time() < deadline && tunnel$is_alive()) {
      Sys.sleep(1)
      if (file.exists(log_file)) {
        lines <- readLines(log_file, warn = FALSE)
        hit <- regmatches(lines,
                          regexpr("https://[a-z0-9-]+\\.trycloudflare\\.com", lines))
        if (length(hit)) public_url <- paste0(hit[1], mcp_path)
      }
    }
    if (is.na(public_url)) {
      warning("Couldn't create the public link (firewall or no internet?). ",
              "Desktop apps can still use the local link.")
    }
  }

  stop_fn <- function() {
    if (!is.null(tunnel) && tunnel$is_alive()) tunnel$kill()
    if (server$is_alive()) server$kill()
    invisible(TRUE)
  }

  message("\nWear-IT AI connection is ON\n",
          "  Desktop AI apps : ", local_url, "\n",
          if (!is.na(public_url)) paste0("  Web AI apps     : ", public_url, "\n") else "",
          "Paste a link into your AI tool's Connectors / MCP settings.\n",
          "Keep R open while you use it.")

  invisible(list(
    local_url  = local_url,
    public_url = public_url,
    is_running = function() server$is_alive(),
    stop       = stop_fn
  ))
}
