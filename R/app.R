# UI function
launch_app_ui <- function() {
  shiny::navbarPage(
    "Navigation",
    header = tagList(
      tags$head(
        # Use the resource path instead of relative path
        tags$link(rel = "stylesheet", type = "text/css", href = "www/shiny.css"),
        tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"),
        tags$script(src = "https://cdn.jsdelivr.net/npm/@panzoom/panzoom@4/dist/panzoom.min.js"),
        tags$script(HTML("mermaid.initialize({ startOnLoad: false, theme: 'default' });"))
      ),
      tags$script(HTML("
        $(document).on('shiny:connected', function() {
          var ddvTab = $('a:contains(\"Data Dictionary Viewer\")').attr('href');
          $(ddvTab).css({
            'background-color': 'transparent',
            'margin': '0',
            'padding': '0',
            'border-radius': '0',
            'box-shadow': 'none'
          });
        });
      "))
    ),
    # Home
    tabPanel("Home",
             h1("Purpose of this tool"),
             p("This is a human accessible tool to help pull data and generate codebooks for Wear-IT users")),
    # Pull data
    tabPanel("Data pull",
             p("This is where you can pull data down from Wear-IT. Just supply the study ID number of the study you want to pull data from and then click the button"),
             textInput(inputId = "studyID", label = "Insert Study ID"),
             passwordInput(inputId = "apiToken", label = "Insert Api Token"),
             selectInput(inputId = "keyringToken",
                         label = "Or select saved key",
                         choices = keyring::key_list()),
             selectInput(inputId = "base_URL", label = "WearIT URL",
                         choices = c("wearables-survey" = "https://wearables.vmhost.psu.edu/wearables-survey/api",
                                     "wearables-survey_sdb" = "https://wearables.vmhost.psu.edu/wearables-survey_sdb/api")),
             actionButton(inputId = "pullDataButton", label = "Pull Data from Wear-IT")),
    # Codebooks
    navbarMenu(
      "Codebook",
      tabPanel("Codebook Generator",
               p("Select what you want included in your codebook"),
               shinyTree("codebookOptions", checkbox = TRUE, themeIcons = FALSE, theme = "proton"),
               textAreaInput("title", "Title", value = "", rows = 1, resize = "horizontal"),
               textAreaInput("authors", "Authors", value = "", rows = 1, resize = "horizontal"),
               textAreaInput("funding", "Funding", value = "", rows = 1, resize = "vertical"),
               textAreaInput("abstract", "Abstract", value = "", rows = 1, resize = "vertical"),
               textAreaInput("summary", "Summary", value = "", rows = 1, resize = "vertical"),
               p("Press the button to generate a codebook from the data you pulled down"),
               actionButton(inputId = "generateCodebook", label = "Generate Codebook")),
      tabPanel("Codebook Viewer",
               uiOutput("codebook"))
    ),
    # Data Dictionary
    navbarMenu(
      "Data Dictionary",
      tabPanel("Data Dictionary Generator",
               p("Press the button to generate a data dictionary from the data you pulled down"),
               actionButton(inputId = "generateDataDictionary", label = "Generate Data Dictionary")),
      tabPanel("Data Dictionary Viewer",
               div(class = "no-tab-style",
                   uiOutput("dataDictionary")))
    ),
    # Flowchart
    tabPanel(
      "Flowchart",
      fluidPage(
        selectInput(inputId = "survey",
                    label = "Select survey to generate flowchart for",
                    choices = NULL),
        actionButton(inputId = "generateFlowChart", label = "Generate Flow Chart"),
        uiOutput("surveyTree")
      )
    ),
    # AI Study Generator
    tabPanel(
      "AI Study Generator",
      p("This allows you to connect with Kimi-K2.5 to generate a study design via AI.
         You can then also ask to modify the study design if changes are needed.
        Directions: Describe the study you would like to run in as much detail as possible.
        Additionally, provide AI URL and API key. You can store your API key in a .env file in app location as 'API_KEY'"),
      passwordInput(inputId = "AIApiToken", label = "Insert AI Api Token", value = Sys.getenv("API_KEY")),
      textAreaInput("AI_URL", "Insert URL", value = "https://genai-fa2026-resource-1.services.ai.azure.com/api/projects/Ethan_Kile_GenAI_Project/openai/v1", autoresize = TRUE, resize = "horizontal"),
      textAreaInput("aiGenerationPrompt", "AI Study Generation Prompt",
                    value = "Generate me a study looking to understand the longitudinal process of people in recovery. Create 1 survey that is delivered 10 times daily. For this survey, Create questions that will cover a wide range of the possible daily processes that a recovery researcher may care about. Additionally, create baseline assessment survey with questions that are measured at 1 time point for each person. This baseline assessment should ask all relevant covariate information. Things like demographics, ses, drug use history, etc.",
                    rows = 3, resize = "both"),
      actionButton(inputId = "generateAIStudy", label = "Generate AI Study"),
      textAreaInput("aiModificationPrompt", "AI Study Modification Prompt",
                    value = "For the questions that ask about sadness and happiness, they measure multiple component (for the postive, its happy and content, for the negative sad anxious and upset). Instead of combining them into 1 question, make them multiple questions.",
                    rows = 3, resize = "both"),
      actionButton(inputId = "modifyAIStudy", label = "Modify AI Study")
    )
  )
}

# Server function
launch_app_server <- function(input, output, session) {

  # Get package directory once at the start
  pkg_dir <- system.file(package = "WearItReadR")
  codebook_dir <- file.path(pkg_dir, "Codebook_RMD")
  python_dir <- file.path(pkg_dir, "python")

  #--------------------
  # Pull Data Page
  #--------------------
  observeEvent(input$pullDataButton, {
    token <- if (input$apiToken != "") {
      input$apiToken
    } else {
      keyring::key_get(input$keyringToken)
    }
    tryCatch({
      showNotification("Pulling Data...", type = "message")
      saveData(study_ID = input$studyID, apiToken = token, shiny = TRUE,
               base_URL = input$base_URL, pull = TRUE)
      showNotification("Finished!", type = "message")
    }, error = function(e) {
      showNotification("Error pulling data", type = "error")
    })
  })

  #-----------------------
  # Codebook
  #-----------------------
  dataTypes <- c("FreeResponse", "InformationalFullscreen", "MultipleChoice",
                 "MultipleSelect", "MultipleSlider", "Slider", "TimePicker", "TimeScaleSlider", "Block", "EndBlock")
  output$codebookOptions <- renderTree({
    list(
      "Title Page" = structure(list(
        "Name of Study" = "",
        "Authors" = "",
        "Study Metadata" = "",
        "Desired Graphic" = "",
        "Funding" = ""
      )),
      "Abstract" = "",
      "Effective Summary" = "",
      "Data Types" = structure(
        setNames(as.list(rep("", length(dataTypes))), dataTypes)
      ),
      "Variable Pages" = structure(list(
        "Histograms" = "",
        "Missingness Page" = "",
        "Descriptives" = "",
        "Bar Plot" = "",
        "Frequency Table" = "",
        "Type of data" = "",
        "Way question was delivered" = "",
        "Screenshot" = "",
        "Skip Logic" = ""
      )),
      "Include Data" = ""
    )
  })

  observeEvent(input$generateCodebook, {
    codebookOptions <- tolower(get_selected(input$codebookOptions, format = "names"))
    tryCatch({
      showNotification("Generating codebook...", type = "message")
      generateCodebook(shiny = TRUE,
                       codebookChunkDisplayOptions = codebookOptions,
                       title = input$title,
                       authors = input$authors,
                       funding = input$funding,
                       abstract = input$abstract,
                       summary = input$summary)
      showNotification("Codebook Generation Complete!", type = "message")
      output$codebook <- renderUI({
        tags$iframe(src = paste0("codebook/Codebook.html?", as.numeric(Sys.time())),
                    width = "100%", height = "800px",
                    frameborder = 0, scrolling = "auto")
      })
    }, error = function(e) {
      showNotification(paste("Error generating codebook:", e$message), type = "error")
      print(e)
    })
  })

  # Use pkg_dir instead of hardcoded path
  if (file.exists(file.path(codebook_dir, "Codebook.html"))) {
    output$codebook <- renderUI({
      tags$iframe(src = paste0("codebook/Codebook.html?", as.numeric(Sys.time())),
                  width = "100%", height = "800px",
                  frameborder = 0, scrolling = "auto")
    })
  } else {
    showNotification("No Codebook has been generated. Press 'Generate Codebook' to generate one.", type = "message")
  }

  #---------------------------------------------
  # Data Dictionary
  #---------------------------------------------
  observeEvent(input$generateDataDictionary, {
    tryCatch({
      showNotification("Generating data dictionary...", type = "message")
      generateDataDictionary(shiny = TRUE)
      showNotification("Data dictionary generation complete!", type = "message")
      output$dataDictionary <- renderTable({
        read.csv(file.path(codebook_dir, "DataDictionary.csv"))
      })
    }, error = function(e) {
      showNotification(paste("Error generating data dictionary:", e$message), type = "error")
      print(e)
    })
  })

  if (file.exists(file.path(codebook_dir, "DataDictionary.csv"))) {
    output$dataDictionary <- renderTable({
      read.csv(file.path(codebook_dir, "DataDictionary.csv"))
    })
  }

  #---------------------------------------------
  # Flowchart
  #---------------------------------------------
  blockMapParsed <- reactiveVal(NULL)

  observe({
    blockmap_path <- file.path(codebook_dir, "Data/blockMap.csv")
    if (file.exists(blockmap_path)) {
      blockMap <- read.csv(blockmap_path)
      choices <- unique(blockMap$Survey[!is.na(blockMap$Survey)])
      updateSelectInput(session, "survey", choices = choices)
    }
  })

  renderMermaidUI <- function(mermaid_code) {
    tagList(
      tags$div(
        style = "width: 100%; height: 600px; border: 1px solid #ddd; overflow: hidden; position: relative;",
        tags$div(
          id = "mermaid-container",
          style = "width: 100%; height: 100%; cursor: grab;"
        )
      ),
      tags$script(HTML(sprintf("
        (function() {
          var diagram = %s;
          mermaid.render('mermaid-svg', diagram).then(function(result) {
            document.getElementById('mermaid-container').innerHTML = result.svg;
            setTimeout(function() {
              var el = document.getElementById('mermaid-container');
              var pz = Panzoom(el, { maxScale: 10, minScale: 0.1 });
              el.parentElement.addEventListener('wheel', pz.zoomWithWheel);
            }, 300);
          });
        })();
      ", jsonlite::toJSON(mermaid_code, auto_unbox = TRUE))))
    )
  }

  observeEvent(input$generateFlowChart, {
    req(input$survey)
    responseKey <- read.csv(file.path(codebook_dir, "Data/responseKey.csv"))
    blockMapParsed(parseBySurvey(survey = input$survey, shiny = TRUE))
    mermaid_code <- generateSurveyTree(blockMapParsed = blockMapParsed(),
                                       responseKey = responseKey,
                                       shiny = TRUE)
    output$surveyTree <- renderUI({ renderMermaidUI(mermaid_code) })
  })

  #---------------------------------------------
  # AI Codebooks
  #---------------------------------------------
  # Generate AI Study
  observeEvent(input$generateAIStudy, {
    tryCatch({
      req(input$AI_URL, input$AIApiToken, input$aiGenerationPrompt)
      showNotification("All requirements avail...", type = "message")

      schema_dir <- file.path(pkg_dir, "schema")
      output_dir <- file.path(codebook_dir, "Data")

      py_run_string(
        "import importlib
import importlib.util
packages = ['pandas', 'langchain_openai', 'jsonschema', 'langchain_core']
missing = [p for p in packages if importlib.util.find_spec(p) is None]
")

      if (length(py$missing) > 0) {
        showNotification("Installing AI dependencies, this may take a moment...", type = "message")
        py_require(py$missing)
      }
      showNotification("Dependencies ok...", type = "message")

      source_python(file.path(python_dir, "aiStudyGenerator.py"))
      showNotification("Python sourced...", type = "message")

      generate_ai_study(
        url         = input$AI_URL,
        api_token   = input$AIApiToken,
        query       = input$aiGenerationPrompt,
        schema_path = schema_dir,
        output_path = output_dir
      )

      parseJsonSpec(get_resource_path("Codebook_RMD", "Data", "study_output.json"))
      showNotification("Study Generated!", type = "message")

    }, error = function(e) {
      showNotification(paste("Error generating AI study:", e$message), type = "error")
      print(e)
    })
  })

  # Modify AI Study
  observeEvent(input$modifyAIStudy, {
    tryCatch({
      req(input$AI_URL, input$AIApiToken, input$aiModificationPrompt)
      showNotification("All requirements available...", type = "message")

      schema_dir <- file.path(pkg_dir, "schema")
      output_dir <- file.path(codebook_dir, "Data")

      py_run_string(
        "import importlib
import importlib.util
packages = ['pandas', 'langchain_openai', 'jsonschema', 'langchain_core']
missing = [p for p in packages if importlib.util.find_spec(p) is None]
")

      if (length(py$missing) > 0) {
        showNotification("Installing AI dependencies, this may take a moment...", type = "message")
        py_install(py$missing, pip = TRUE)
      }
      showNotification("Dependencies ok...", type = "message")

      source_python(file.path(python_dir, "aiStudyModifier.py"))
      showNotification("Python sourced...", type = "message")

      modify_ai_study(
        url         = input$AI_URL,
        api_token   = input$AIApiToken,
        query       = input$aiModificationPrompt,
        schema_path = schema_dir,
        output_path = output_dir
      )

      parseJsonSpec(get_resource_path("Codebook_RMD", "Data", "study_output.json"))
      showNotification("Study Modified!", type = "message")

    }, error = function(e) {
      showNotification(paste("Error modifying AI study:", e$message), type = "error")
      print(e)
    })
  })
}


#' Launch WearItReadR Application
#'
#' Launches the interactive Shiny application for managing Wear-IT data,
#' generating codebooks, creating data dictionaries, and visualizing surveys.
#'
#' @return A Shiny app object
#' @importFrom shiny shinyApp addResourcePath
#' @importFrom shinyTree shinyTree
#' @importFrom dotenv load_dot_env
#' @export
wearitreadr <- function() {
  library(shiny)
  library(shinyTree)
  library(shinyFiles)
  library(DiagrammeR)
  library(jsonlite)
  library(reticulate)
  library(dotenv)

  # Get the installed package directory
  pkg_dir <- system.file(package = "WearItReadR")

  if (pkg_dir == "") {
    stop("Could not find WearItReadR package installation.")
  }

  # Set working directory to package directory
  # This makes all relative paths work for all my functions
  old_wd <- getwd()
  on.exit(setwd(old_wd))  # Restore when done
  setwd(pkg_dir)

  # Check for .env
  env_path <- file.path(pkg_dir, ".env")
  if (file.exists(env_path)) {
    load_dot_env(env_path)
  }

  # Use installed package paths
  addResourcePath("codebook", file.path(pkg_dir, "Codebook_RMD"))
  addResourcePath("www", file.path(pkg_dir, "www"))

  shinyApp(ui = launch_app_ui(), server = launch_app_server)
}
