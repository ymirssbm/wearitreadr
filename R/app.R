launch_app_ui <- function() {
  conflicted::conflicts_prefer(shinydashboard::box)

  dashboardPage(
    skin = "blue",

    # ===== HEADER =====
    dashboardHeader(
      title = tags$div(
        style = "display: flex; align-items: center; gap: 10px;",
        tags$img(src = "www/WearIT_logo.png",
                 style = "width: 40px; height: 40px; object-fit: contain; display: block;"),
        tags$span("Wear-IT ReadR",
                  style = "font-weight: 700; color: white; font-size: 18px;")
      ),
      titleWidth = 280
    ),

    # ===== SIDEBAR =====
    dashboardSidebar(
      width = 280,
      sidebarMenu(
        id = "sidebar_menu",

        menuItem("Home",
                 tabName = "home",
                 icon = icon("home")),

        menuItem("Data Pull",
                 tabName = "datapull",
                 icon = icon("download")),

        menuItem("Codebook",
                 icon = icon("book"),
                 startExpanded = TRUE,
                 menuSubItem("Codebook Generator",
                             tabName = "codebook_gen",
                             icon = icon("cog")),
                 menuSubItem("Codebook Viewer",
                             tabName = "codebook_view",
                             icon = icon("eye"))
        ),

        menuItem("Data Dictionary",
                 icon = icon("table"),
                 startExpanded = TRUE,
                 menuSubItem("Data Dictionary Generator",
                             tabName = "datadict_gen",
                             icon = icon("cog")),
                 menuSubItem("Data Dictionary Viewer",
                             tabName = "datadict_view",
                             icon = icon("eye"))
        ),

        menuItem("Study Flowchart",
                 tabName = "flowchart",
                 icon = icon("project-diagram")),

        menuItem("AI Study Generator",
                 tabName = "ai")
      )
    ),

    # ===== BODY =====
    dashboardBody(
      # Custom CSS
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css",
                  href = paste0("www/shiny.css?v=", Sys.time())),
        tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"),
        tags$script(src = "https://cdn.jsdelivr.net/npm/@panzoom/panzoom@4/dist/panzoom.min.js"),
        tags$script(HTML("mermaid.initialize({ startOnLoad: false, theme: 'default' });")),

        tags$script(HTML("
Shiny.addCustomMessageHandler('jsCode', function(message) {
  eval(message.code);
});
")),
        tags$script(HTML("
  $(document).ready(function() {
    $('body').removeClass('sidebar-collapse');
  });
")),

        # Add spinner control functions
        tags$script(HTML("
function showChatSpinner() {
  document.getElementById('chatSpinner').style.display = 'block';
  document.getElementById('sendChat').disabled = true;
}

function hideChatSpinner() {
  document.getElementById('chatSpinner').style.display = 'none';
  document.getElementById('sendChat').disabled = false;
}

// Scroll chat to bottom
function scrollChatToBottom() {
  var chatBox = document.getElementById('chatHistory');
  chatBox.scrollTop = chatBox.scrollHeight;
}
")),

        # ===== Mermaid PNG export function =====
        tags$script(HTML("
  function exportMermaidPNG() {
    try {
      var svgEl = document.querySelector('#mermaid-container svg');
      if (!svgEl) { alert('Please generate the flowchart first.'); return; }

      // Measure the LIVE element (correct fonts/metrics) before cloning
      var bbox = svgEl.getBBox();
      var padding = 20;
      var x = bbox.x - padding;
      var y = bbox.y - padding;
      var width = bbox.width + padding * 2;
      var height = bbox.height + padding * 2;

      if (!width || !height) {
        alert('Could not determine flowchart size for export.');
        return;
      }

      var clone = svgEl.cloneNode(true);
      clone.removeAttribute('style');
      clone.setAttribute('viewBox', x + ' ' + y + ' ' + width + ' ' + height);
      clone.setAttribute('width', width);
      clone.setAttribute('height', height);
      clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

      // Inline all same-origin page CSS so text/fonts render the same way
      // standalone as they do on-screen (fixes text getting clipped/wrong width)
      var cssText = '';
      for (var i = 0; i < document.styleSheets.length; i++) {
        try {
          var rules = document.styleSheets[i].cssRules || document.styleSheets[i].rules;
          if (!rules) continue;
          for (var j = 0; j < rules.length; j++) {
            cssText += rules[j].cssText + '\\n';
          }
        } catch (e) {
          // Cross-origin stylesheet (e.g. CDN font/theme) - can't read its rules, skip
        }
      }
      var styleEl = document.createElementNS('http://www.w3.org/2000/svg', 'style');
      styleEl.textContent = cssText;
      clone.insertBefore(styleEl, clone.firstChild);

      var scale = 2; // higher = sharper PNG

      var svgData = new XMLSerializer().serializeToString(clone);
      var svgBlob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
      var url = URL.createObjectURL(svgBlob);

      var img = new Image();
      img.onload = function() {
        try {
          var canvas = document.createElement('canvas');
          canvas.width = width * scale;
          canvas.height = height * scale;
          var ctx = canvas.getContext('2d');
          ctx.fillStyle = '#ffffff';
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
          URL.revokeObjectURL(url);

          canvas.toBlob(function(blob) {
            var a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = 'flowchart.png';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
          });
        } catch (err) {
          console.error('exportMermaidPNG canvas error:', err);
          alert('Export failed while drawing the image: ' + err.message);
        }
      };
      img.onerror = function(err) {
        console.error('exportMermaidPNG image load error:', err);
        URL.revokeObjectURL(url);
        alert('Could not load the flowchart image for export.');
      };
      img.src = url;

    } catch (err) {
      console.error('exportMermaidPNG error:', err);
      alert('Export failed: ' + err.message);
    }
  }
")),

        # Flow chart download
        tags$script(HTML("
Shiny.addCustomMessageHandler('triggerExport', function(msg) {
  if (window.exportMermaidPNG) {
    exportMermaidPNG();
  } else {
    alert('Please generate the flowchart first.');
  }
});
")),
      ),

      tabItems(
        # Home
        tabItem(
          tabName = "home",
          fluidRow(
            box(
              width = 12,
              title = "Purpose of this tool",
              status = "primary",
              solidHeader = TRUE,
              p("This is a human accessible tool to help pull data and generate codebooks for Wear-IT users")
              ),
            # Set wd button
            box(
              width = 12,
              title = "Set App Working Directory",
              status = "primary",
              solidHeader = TRUE,
              p("Use this to set the working directory of the App. It will reference this directory when saving and viewing, codebooks, data dictionaries, and study flowchart exports"),
              shinyDirButton(
                id = "setWorkingDirectory",
                label = "Select Working Directory",
                title = "Please select a file",
                multiple = FALSE
              )
            ),
          )
        ),

        # ===== DATA PULL TAB =====
        tabItem(
          tabName = "datapull",
          h2("Pull Data from Wear-IT"),

          fluidRow(
            box(
              width = 12,
              title = "Enter Study Credentials",
              status = "primary",
              solidHeader = TRUE,

              fluidRow(
                column(6,
                       textInput("studyID", "Study ID", placeholder = "Enter Study ID"),
                       passwordInput("apiToken", "API Token", placeholder = "Enter API Token"),
                       selectInput("keyringToken", "Or select saved key", choices = keyring::key_list())
                ),
                column(6,
                       selectInput("base_URL", "Wear-IT URL",
                                   choices = c(
                                     "wearables-survey" = "https://wearables.vmhost.psu.edu/wearables-survey/api",
                                     "wearables-survey_sdb" = "https://wearables.vmhost.psu.edu/wearables-survey_sdb/api"
                                   )
                       ),
                       br(),
                       actionButton("pullDataButton", "Pull Data from Wear-IT",
                                    icon = icon("download"),
                                    class = "btn-lg",
                                    style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 1rem 2rem; font-weight: 600;")
                )
              ),

              div(style = "margin-top: 1rem; padding: 1rem; background: #e3f2fd; border-radius: 5px;",
                  icon("lock"), " Your credentials are used securely and never stored."
              )
            )
          )
        ),

        # ===== CODEBOOK GENERATOR TAB =====
        tabItem(
          tabName = "codebook_gen",
          h2("Codebook Generator"),

          fluidRow(
            box(
              width = 6,
              title = "Codebook Options",
              status = "primary",
              solidHeader = TRUE,
              shinyTree("codebookOptions", checkbox = TRUE, themeIcons = FALSE, theme = "proton")
            ),

            box(
              width = 6,
              title = "Study Metadata",
              status = "primary",
              solidHeader = TRUE,
              textInput("title", "Title", placeholder = "Enter title"),
              textInput("authors", "Authors", placeholder = "Enter authors"),
              textAreaInput("funding", "Funding", placeholder = "Enter funding information", rows = 3),
              textAreaInput("abstract", "Abstract", placeholder = "Enter abstract", rows = 4),
              textAreaInput("summary", "Summary", placeholder = "Enter summary", rows = 4)
            )
          ),

          fluidRow(
            box(
              width = 12,
              actionButton("generateCodebook", "Generate Codebook",
                           icon = icon("file-alt"),
                           class = "btn-lg",
                           style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 1rem 2rem; font-weight: 600;")
            )
          )
        ),

        # ===== CODEBOOK VIEWER TAB =====
        tabItem(
          tabName = "codebook_view",
          h2("Codebook Viewer"),

          fluidRow(
            box(
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              uiOutput("codebook")
            )
          )
        ),

        # ===== DATA DICTIONARY GENERATOR TAB =====
        tabItem(
          tabName = "datadict_gen",
          h2("Data Dictionary Generator"),

          fluidRow(
            box(
              width = 12,
              title = "Generate Data Dictionary",
              status = "primary",
              solidHeader = TRUE,
              p("Press the button to generate a data dictionary from the data you pulled down."),
              actionButton("generateDataDictionary", "Generate Data Dictionary",
                           icon = icon("table"),
                           class = "btn-lg",
                           style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 1rem 2rem; font-weight: 600;")
            )
          )
        ),

        # ===== DATA DICTIONARY VIEWER TAB =====
        tabItem(
          tabName = "datadict_view",
          h2("Data Dictionary Viewer"),

          fluidRow(
            box(
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              uiOutput("dataDictionary")
            )
          )
        ),

        # ===== FLOWCHART TAB =====
        tabItem(
          tabName = "flowchart",
          h2("Flowchart Visualization"),

          fluidRow(
            box(
              width = 12,
              title = "Generate Flow Chart",
              status = "primary",
              solidHeader = TRUE,
              fluidRow(
                column(6,
                       selectInput("survey", "Select survey", choices = NULL)
                ),
                column(6,
                       actionButton("generateFlowChart", "Generate Flow Chart",
                                    style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 0.75rem 1.5rem; font-weight: 600;")
                )
              )
            )
          ),

          fluidRow(
            box(
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              actionButton("exportPNG", "Export PNG",
                           icon = icon("download"),
                           style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 0.5rem 1rem; font-weight: 600; margin-bottom: 10px;"),
              tags$small("Generate a flowchart before exporting.",
                         style = "color: #888; margin-left: 10px;"),
              uiOutput("surveyTree")
            )
          )
        ),

        # ===== AI STUDY GENERATOR TAB =====
        tabItem(
          tabName = "ai",
          h2("AI Study Assistant"),

          fluidRow(
            box(
              width = 12,
              title = "Configuration",
              status = "primary",
              solidHeader = TRUE,
              collapsible = TRUE,
              collapsed = TRUE,

              fluidRow(
                column(6,
                       passwordInput("AIApiToken", "AI API Token",
                                     value = Sys.getenv("API_KEY"),
                                     placeholder = "Enter your API token")
                ),
                column(6,
                       textInput("AI_URL", "AI URL",
                                 value = "https://genai-fa2026-resource-1.services.ai.azure.com/api/projects/Ethan_Kile_GenAI_Project/openai/v1")
                )
              )
            )
          ),

          # Chat Interface
          fluidRow(
            box(
              width = 12,
              title = "Chat with AI Assistant",
              status = "primary",
              solidHeader = TRUE,

              # Chat history display
              div(
                id = "chatHistory",
                style = "height: 400px; overflow-y: auto; padding: 15px; background: #f9f9f9; border-radius: 5px; margin-bottom: 15px; position: relative;",
                uiOutput("chatMessages"),
                # Spinner inside the chat box (hidden by default)
                div(id = "chatSpinner",
                    style = "display: none; text-align: center; padding: 10px;",
                    tags$i(class = "fa fa-spinner fa-spin fa-2x", style = "color: #3c8dbc;"),
                    br(),
                    tags$small("Processing...", style = "color: #666;"))
              ),

              # Input area
              fluidRow(
                column(10,
                       textAreaInput("chatInput",
                                     label = NULL,
                                     placeholder = "Ask me to generate a study, modify an existing one, or ask questions... (Press Enter to send, Shift+Enter for new line)",
                                     rows = 2,
                                     width = "100%")
                ),
                column(2,
                       br(),
                       actionButton("sendChat", "Send",
                                    icon = icon("paper-plane"),
                                    class = "btn-lg",
                                    style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 0.75rem 1.5rem; font-weight: 600; width: 100%;"),
                       br(), br(),
                       actionButton("clearChat", "Clear",
                                    icon = icon("trash"),
                                    style = "width: 100%;")
                )
              ),

              # Quick actions
              div(
                style = "margin-top: 10px;",
                actionButton("helpBtn", "Help", icon = icon("question-circle"),
                             style = "margin-right: 5px;"),
                actionButton("exampleGenerate", "Example: Generate", icon = icon("lightbulb"),
                             style = "margin-right: 5px;"),
                actionButton("exampleModify", "Example: Modify", icon = icon("lightbulb"))
              )
            )
          ),

          # Advanced mode (collapsed by default)
          fluidRow(
            box(
              width = 12,
              title = "Advanced Mode (Direct Prompts)",
              status = "primary",
              solidHeader = TRUE,
              collapsible = TRUE,
              collapsed = TRUE,

              fluidRow(
                column(6,
                       textAreaInput("aiGenerationPrompt", "Direct Generation Prompt",
                                     value = "Generate me a study looking to understand the longitudinal process of people in recovery...",
                                     rows = 5),
                       actionButton("generateAIStudy", "Generate (Direct)",
                                    class = "btn-lg",
                                    style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 1rem 2rem; font-weight: 600;")
                ),
                column(6,
                       textAreaInput("aiModificationPrompt", "Direct Modification Prompt",
                                     value = "For the questions that ask about sadness and happiness...",
                                     rows = 5),
                       actionButton("modifyAIStudy", "Modify (Direct)",
                                    class = "btn-lg",
                                    style = "background: #3c8dbc; color: white; border: none; border-radius: 8px; padding: 1rem 2rem; font-weight: 600;")
                )
              )
            )
          )
        )
      )
    )
  )
}


# Server function - SAME AS BEFORE, just remove the navigation observers
launch_app_server <- function(input, output, session) {

  # Reset wd on exit
  original_wd <- getwd()

  session$onSessionEnded(function() {
    setwd(original_wd)
  })

  shinyjs::useShinyjs()
  # Get package directory once at the start
  pkg_dir <- system.file(package = "WearItReadR")
  codebook_dir <- file.path(pkg_dir, "Codebook_RMD")
  python_dir <- file.path(pkg_dir, "python")

  # NOTE: Remove all the navigation observeEvent() functions
  # shinydashboard handles navigation automatically via tabName

  # Rest of your server code stays exactly the same...
  # (All the observeEvent for buttons, data processing, etc.)


  #-----------------------
  # Set working directory
  #-----------------------

  volumes <- c(Home = fs::path_home())

  shinyDirChoose(input, "setWorkingDirectory",
                 roots = volumes,
                 session = session)

  working_dir <- reactiveVal(NULL)

  observeEvent(input$setWorkingDirectory, {
    req(is.list(input$setWorkingDirectory))
    selected_dir <- parseDirPath(volumes, input$setWorkingDirectory)
    if (length(selected_dir) > 0) {
      working_dir(selected_dir)
      setwd(selected_dir)
      addResourcePath("userwd", selected_dir)

      # Reset the AI assistant so it re-initializes against the new working
      # directory next time it's needed (its output_path and its internal
      # "does a study already exist" check are both baked in at creation)
      assistant(NULL)

      showNotification(paste("Working directory set to:", selected_dir), type = "message", duration = 5)
    }

    if (file.exists(file.path(working_dir(), "Codebook.html"))) {
      output$codebook <- renderUI({
        tags$iframe(src = paste0("userwd/Codebook.html?", as.numeric(Sys.time())),
                    width = "100%", height = "800px",
                    frameborder = 0, scrolling = "auto")
      })
    }
    if (file.exists("DataDictionary.csv")) {
      output$dataDictionary <- renderTable({
        read.csv("DataDictionary.csv")
      })
    }

    if (file.exists("blockMap.csv")) {
      blockMap <- read.csv("blockMap.csv")
      choices <- unique(blockMap$Survey[!is.na(blockMap$Survey)])
      updateSelectInput(session, "survey", choices = choices)
    }

  })

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
      notif_id <- showNotification("Pulling Data...", type = "message", duration = NULL)
      saveData(study_ID = input$studyID, apiToken = token,
               base_URL = input$base_URL, pull = TRUE, skip_readline = TRUE)
      removeNotification(notif_id)
      showNotification("Finished!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error pulling data:", conditionMessage(e)), type = "error")
    })

    # Update flowchart options for new blockMap
    if (file.exists("blockMap.csv")) {
      blockMap <- read.csv("blockMap.csv")
      choices <- unique(blockMap$Survey[!is.na(blockMap$Survey)])
      updateSelectInput(session, "survey", choices = choices)
    }
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
    req(working_dir())
    codebookOptions <- tolower(get_selected(input$codebookOptions, format = "names"))
    tryCatch({
      notif_id <- showNotification("Generating codebook...", type = "message", duration = NULL)
      generateCodebook(
        shiny = TRUE,
        codebookChunkDisplayOptions = codebookOptions,
        title = input$title,
        authors = input$authors,
        funding = input$funding,
        abstract = input$abstract,
        summary = input$summary,
        screenshotDir = file.path(working_dir(), "screenshots"),
        output_file = file.path(working_dir(), "Codebook.html")
      )
      removeNotification(notif_id)
      showNotification("Codebook Generation Complete!", type = "message")
      addResourcePath("userwd", working_dir())

      output$codebook <- renderUI({
        tags$iframe(src = paste0("userwd/Codebook.html?", as.numeric(Sys.time())),
                    width = "100%", height = "800px",
                    frameborder = 0, scrolling = "auto")
      })
    }, error = function(e) {
      showNotification(paste("Error generating codebook:", e$message), type = "error")
      print(e)
    })
  })

  if (file.exists("Codebook.html")) {
    output$codebook <- renderUI({
      tags$iframe(src = paste0("userwd/Codebook.html?", as.numeric(Sys.time())),
                  width = "100%", height = "800px",
                  frameborder = 0, scrolling = "auto")
    })
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
        read.csv("DataDictionary.csv")
      })
    }, error = function(e) {
      showNotification(paste("Error generating data dictionary:", e$message), type = "error")
      print(e)
    })
  })

  if (file.exists("DataDictionary.csv")) {
    output$dataDictionary <- renderTable({
      read.csv("DataDictionary.csv")
    })

  }

  #---------------------------------------------
  # Flowchart
  #---------------------------------------------
  #---------------------------------------------
  # Flowchart
  #---------------------------------------------

  observe({
    if (file.exists("blockMap.csv")) {
      blockMap <- read.csv("blockMap.csv")
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

  mermaid_code <- reactiveVal(NULL)

  observeEvent(input$generateFlowChart, {
    tryCatch({
      req(input$survey)
      showNotification("Generating flowchart...", type = "message")
      responseKey <- read.csv("responseKey.csv")
      mermaid_code(generateSurveyFlowchart(blockMap = read.csv("blockMap.csv"), survey = input$survey,
                                           responseKey = responseKey, shiny = TRUE))
      output$surveyTree <- renderUI({ renderMermaidUI(mermaid_code()) })
      showNotification("Flowchart generated successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error generating flowchart:", e$message), type = "error", duration = 10)
      print(paste("Full error details:", e))
      print(traceback())
    })
  })

  # Replaces the old downloadHandler-based exportPNG
  observeEvent(input$exportPNG, {
    req(mermaid_code())
    session$sendCustomMessage("triggerExport", list())
  })


  #---------------------------------------------
  # AI Chatbot Assistant (bring your own AI)
  #---------------------------------------------

  welcome <- list(list(
    role = "assistant",
    content = "Hi! I'm your AI Study Assistant. Enter your AI URL and API key above, then ask me to create or change a study. Type 'help' to see what I can do."
  ))
  chat_messages  <- reactiveVal(welcome)
  assistant      <- reactiveVal(NULL)   # setWorkingDirectory observer already resets this
  tool_log       <- new.env()
  tool_log$names <- character()

  tool_labels <- c(
    get_study_schema         = "read the study schema",
    search_item_repository   = "searched the item repository",
    get_current_study        = "read your current study",
    save_study               = "validated & saved the study",
    pull_data                = "pulled data from Wear-IT",
    generate_codebook        = "generated the codebook",
    generate_data_dictionary = "generated the data dictionary",
    survey_flowchart         = "built a survey flowchart"
  )

  add_msg <- function(role, content) {
    msgs <- chat_messages()
    msgs[[length(msgs) + 1]] <- list(role = role, content = content)
    chat_messages(msgs)
  }

  # Changing the URL or key starts a fresh connection
  observeEvent(list(input$AI_URL, input$AIApiToken), {
    assistant(NULL)
  }, ignoreInit = TRUE)

  get_assistant <- function() {
    if (!is.null(assistant())) return(assistant())
    a <- wearit_chat(
      url     = input$AI_URL,
      api_key = input$AIApiToken,
      dir     = working_dir(),
      on_tool = function(name) tool_log$names <- c(tool_log$names, name)
    )
    assistant(a)
    a
  }

  # One turn of conversation; used by Send and by the Advanced buttons
  run_turn <- function(user_message, show_user = TRUE) {
    if (is.null(working_dir())) {
      add_msg("system", "Please set your working directory on the Home tab first.")
      return(invisible())
    }
    if (show_user) add_msg("user", user_message)

    if (tolower(trimws(user_message)) %in% c("help", "?", "commands", "what can you do")) {
      add_msg("assistant", wearit_help_text(working_dir()))
      return(invisible())
    }

    study_file <- file.path(working_dir(), "study_output.json")
    before <- if (file.exists(study_file)) file.mtime(study_file) else NA
    tool_log$names <- character()

    shinyjs::runjs("document.getElementById('chatSpinner').style.display = 'block';")
    shinyjs::runjs("document.getElementById('sendChat').disabled = true;")

    tryCatch({
      a <- get_assistant()
      reply <- as.character(a$chat(user_message, echo = "none"))

      used <- unique(tool_log$names)
      if (length(used) > 0) {
        nice <- ifelse(used %in% names(tool_labels), tool_labels[used], used)
        add_msg("system", paste("AI", paste(nice, collapse = ", ")))
      }

      if (!nzchar(trimws(reply))) reply <- "Done."
      add_msg("assistant", reply)

      after <- if (file.exists(study_file)) file.mtime(study_file) else NA
      if (!identical(before, after) && !is.na(after)) {
        showNotification("Study saved! You can now generate a codebook.", type = "message")
      }
      if (file.exists(file.path(working_dir(), "blockMap.csv"))) {
        bm <- read.csv(file.path(working_dir(), "blockMap.csv"))
        updateSelectInput(session, "survey",
                          choices = unique(bm$Survey[!is.na(bm$Survey)]))
      }
    }, error = function(e) {
      assistant(NULL)  # reconnect fresh next time
      add_msg("assistant", paste0(
        "Sorry, I couldn't reach your AI. Check your AI URL and API key above.\n\n",
        "Details: ", conditionMessage(e)
      ))
    })

    shinyjs::runjs("document.getElementById('chatSpinner').style.display = 'none';")
    shinyjs::runjs("document.getElementById('sendChat').disabled = false;")
  }

  # Render chat messages
  output$chatMessages <- renderUI({
    messages <- chat_messages()

    if (length(messages) == 0) {
      return(div(
        style = "text-align: center; color: #999; padding: 50px;",
        icon("comments", "fa-3x"), br(), br(),
        "Start a conversation..."
      ))
    }

    message_divs <- lapply(messages, function(msg) {
      if (msg$role == "user") {
        div(style = "background: #3c8dbc; color: white; padding: 10px 15px; border-radius: 15px; margin: 10px 20% 10px 10px; text-align: left;",
            icon("user"), " ", msg$content)
      } else if (msg$role == "assistant") {
        div(style = "background: white; color: #333; padding: 10px 15px; border-radius: 15px; margin: 10px 10px 10px 20%; border: 1px solid #ddd; text-align: left;",
            HTML(markdown::markdownToHTML(text = msg$content, fragment.only = TRUE)))
      } else {
        div(style = "background: #f0f0f0; color: #666; padding: 8px 15px; border-radius: 10px; margin: 10px auto; text-align: center; max-width: 80%; font-style: italic;",
            icon("info-circle"), " ", msg$content)
      }
    })

    tagList(
      message_divs,
      tags$script(HTML("
        setTimeout(function() {
          var chatBox = document.getElementById('chatHistory');
          if (chatBox) chatBox.scrollTop = chatBox.scrollHeight;
        }, 100);
      "))
    )
  })

  # Send
  observeEvent(input$sendChat, {
    req(input$chatInput)
    user_message <- trimws(input$chatInput)
    if (user_message == "") return()
    updateTextAreaInput(session, "chatInput", value = "")
    run_turn(user_message)
  })

  # Clear
  observeEvent(input$clearChat, {
    chat_messages(welcome)
    if (!is.null(assistant())) assistant()$set_turns(list())
    showNotification("Chat cleared", type = "message")
  })

  # Help + examples
  observeEvent(input$helpBtn, {
    updateTextAreaInput(session, "chatInput", value = "help")
  })
  observeEvent(input$exampleGenerate, {
    updateTextAreaInput(session, "chatInput",
                        value = "Create a study measuring stress and anxiety in college students with daily surveys")
  })
  observeEvent(input$exampleModify, {
    updateTextAreaInput(session, "chatInput",
                        value = "Add demographic questions for age, gender, and year in school")
  })

  # Advanced: direct prompts go through the same AI, with the intent forced
  observeEvent(input$generateAIStudy, {
    req(input$aiGenerationPrompt)
    add_msg("system", paste("Direct generation:", input$aiGenerationPrompt))
    run_turn(paste0("Create a NEW study (mode = 'generate'). Request: ",
                    input$aiGenerationPrompt), show_user = FALSE)
  })

  observeEvent(input$modifyAIStudy, {
    req(input$aiModificationPrompt)
    if (is.null(working_dir()) ||
        !file.exists(file.path(working_dir(), "study_output.json"))) {
      add_msg("system", "No study yet. Generate one first.")
      return()
    }
    add_msg("system", paste("Direct modification:", input$aiModificationPrompt))
    run_turn(paste0("MODIFY the current study (mode = 'modify'). Request: ",
                    input$aiModificationPrompt), show_user = FALSE)
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
  library(shinydashboard)
  library(DiagrammeR)
  library(jsonlite)
  library(reticulate)
  library(dotenv)
  library(shinyjs)
  conflicted::conflicts_prefer(shinydashboard::box)

  # Get the installed package directory
  pkg_dir <- system.file(package = "WearItReadR")

  if (pkg_dir == "") {
    stop("Could not find WearItReadR package installation.")
  }

  # Set working directory to package directory
  old_wd <- getwd()
  on.exit(setwd(old_wd))
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
