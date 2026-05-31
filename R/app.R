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
              downloadButton("exportPNG", "Export PNG",
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
  shinyjs::useShinyjs()
  # Get package directory once at the start
  pkg_dir <- system.file(package = "WearItReadR")
  codebook_dir <- file.path(pkg_dir, "Codebook_RMD")
  python_dir <- file.path(pkg_dir, "python")

  # NOTE: Remove all the navigation observeEvent() functions
  # shinydashboard handles navigation automatically via tabName

  # Rest of your server code stays exactly the same...
  # (All the observeEvent for buttons, data processing, etc.)

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
      saveData(study_ID = input$studyID, apiToken = token,
               base_URL = input$base_URL, pull = TRUE, skip_readline = TRUE)
      showNotification("Finished!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error pulling data:", conditionMessage(e)), type = "error")
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

  if (file.exists(file.path(codebook_dir, "Codebook.html"))) {
    output$codebook <- renderUI({
      tags$iframe(src = paste0("codebook/Codebook.html?", as.numeric(Sys.time())),
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

  mermaid_code <- reactiveVal(NULL)

  observeEvent(input$generateFlowChart, {
    tryCatch({
      req(input$survey)
      showNotification("Generating flowchart...", type = "message")
      responseKey <- read.csv(file.path(codebook_dir, "Data/responseKey.csv"))
      blockMapParsed(parseBySurvey(survey = input$survey))
      mermaid_code(generateSurveyFlowchart(blockMapParsed = blockMapParsed(),
                                      responseKey = responseKey, shiny = TRUE))
      output$surveyTree <- renderUI({ renderMermaidUI(mermaid_code()) })
      showNotification("Flowchart generated successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error generating flowchart:", e$message), type = "error", duration = 10)
      print(paste("Full error details:", e))
      print(traceback())
    })
  })

  output$exportPNG <- downloadHandler(
    filename = function() { "flowchart.png" },
    content = function(file) {
      req(mermaid_code())
      encoded <- openssl::base64_encode(mermaid_code())
      encoded <- gsub("\n", "", encoded)          # remove linebreaks
      encoded <- gsub("\\+", "-", encoded)        # URL-safe base64
      encoded <- gsub("/", "_", encoded)          # URL-safe base64
      encoded <- gsub("=", "", encoded)           # remove padding
      url <- paste0("https://mermaid.ink/img/", encoded)
      resp <- httr::GET(url)
      print(httr::status_code(resp))
      writeBin(httr::content(resp, "raw"), file)
    },
    contentType = "image/png"
  )


  #---------------------------------------------
  # AI Chatbot Assistant
  #---------------------------------------------

  # Initialize chatbot reactive values
  chat_messages <- reactiveVal(list())
  assistant <- reactiveVal(NULL)

  # Initialize the assistant when credentials are available
  observe({
    req(input$AI_URL, input$AIApiToken)

    if (is.null(assistant())) {
      tryCatch({
        schema_dir <- file.path(pkg_dir, "schema")
        output_dir <- file.path(codebook_dir, "Data")

        # Check and install dependencies
        py_run_string(
          "import importlib
import importlib.util
packages = ['pandas', 'langchain_openai', 'jsonschema', 'langchain_core']
missing = [p for p in packages if importlib.util.find_spec(p) is None]
")

        if (length(py$missing) > 0) {
          showNotification("Installing AI dependencies...", type = "message", duration = 5)
          py_install(py$missing, pip = TRUE)
        }

        source_python(file.path(python_dir, "aiStudyDispatcher.py"))

        # Create assistant instance
        assistant(py$StudyAssistant(
          url = input$AI_URL,
          api_token = input$AIApiToken,
          schema_path = schema_dir,
          output_path = output_dir
        ))

        # Add welcome message
        chat_messages(list(
          list(role = "assistant",
               content = "Hi! I'm your AI Study Assistant. I can help you generate new studies or modify existing ones. Type 'help' to see what I can do!")
        ))

      }, error = function(e) {
        showNotification(paste("Error initializing assistant:", e$message),
                         type = "error", duration = 10)
      })
    }
  })

  # Render chat messages with auto-scroll
  output$chatMessages <- renderUI({
    messages <- chat_messages()

    if (length(messages) == 0) {
      return(div(
        style = "text-align: center; color: #999; padding: 50px;",
        icon("comments", "fa-3x"),
        br(), br(),
        "Start a conversation..."
      ))
    }

    message_divs <- lapply(messages, function(msg) {
      if (msg$role == "user") {
        div(
          style = "background: #3c8dbc; color: white; padding: 10px 15px; border-radius: 15px; margin: 10px 20% 10px 10px; text-align: left;",
          icon("user"),
          " ",
          msg$content
        )
      } else if (msg$role == "assistant") {
        div(
          style = "background: white; color: #333; padding: 10px 15px; border-radius: 15px; margin: 10px 10px 10px 20%; border: 1px solid #ddd; text-align: left;",
          " ",
          HTML(gsub("\n", "<br>", msg$content))
        )
      } else if (msg$role == "system") {
        div(
          style = "background: #f0f0f0; color: #666; padding: 8px 15px; border-radius: 10px; margin: 10px auto; text-align: center; max-width: 80%; font-style: italic;",
          icon("info-circle"),
          " ",
          msg$content
        )
      }
    })

    # Add auto-scroll JavaScript
    tagList(
      message_divs,
      tags$script(HTML("
      setTimeout(function() {
        var chatBox = document.getElementById('chatHistory');
        if(chatBox) chatBox.scrollTop = chatBox.scrollHeight;
      }, 100);
    "))
    )
  })

  # Main send handler - SIMPLE SYNCHRONOUS VERSION
  observeEvent(input$sendChat, {
    req(input$chatInput, assistant())

    user_message <- trimws(input$chatInput)
    if (user_message == "") return()

    # Add user message immediately
    msgs <- chat_messages()
    msgs[[length(msgs) + 1]] <- list(role = "user", content = user_message)
    chat_messages(msgs)

    # Clear input
    updateTextAreaInput(session, "chatInput", value = "")

    # Show spinner
    shinyjs::runjs("document.getElementById('chatSpinner').style.display = 'block';")
    shinyjs::runjs("document.getElementById('sendChat').disabled = true;")

    # Tiny delay to let UI update
    Sys.sleep(0.05)

    # Process with assistant
    tryCatch({
      result <- assistant()$chat(user_message)

      if (result$action == "generate") {
        source_python(file.path(python_dir, "aiStudyGenerator.py"))
        generate_ai_study(
          url = input$AI_URL,
          api_token = input$AIApiToken,
          query = result$query,
          schema_path = file.path(pkg_dir, "schema"),
          output_path = file.path(codebook_dir, "Data")
        )
        parseJsonSpec(get_resource_path("Codebook_RMD", "Data", "study_output.json"))

        msgs <- chat_messages()
        msgs[[length(msgs) + 1]] <- list(
          role = "assistant",
          content = "✅ Study generated successfully! You can now modify it or generate a codebook."
        )
        chat_messages(msgs)

      } else if (result$action == "modify") {
        source_python(file.path(python_dir, "aiStudyModifier.py"))
        modify_ai_study(
          url = input$AI_URL,
          api_token = input$AIApiToken,
          query = result$query,
          schema_path = file.path(pkg_dir, "schema"),
          output_path = file.path(codebook_dir, "Data")
        )
        parseJsonSpec(get_resource_path("Codebook_RMD", "Data", "study_output.json"))

        msgs <- chat_messages()
        msgs[[length(msgs) + 1]] <- list(
          role = "assistant",
          content = "Study modified successfully!"
        )
        chat_messages(msgs)

      } else {
        response_text <- result$response
        if (is.null(response_text) || response_text == "") {
          response_text <- "I'm having trouble responding right now. Could you try rephrasing that?"
        }

        msgs <- chat_messages()
        msgs[[length(msgs) + 1]] <- list(
          role = "assistant",
          content = response_text
        )
        chat_messages(msgs)
      }

    }, error = function(e) {
      msgs <- chat_messages()
      msgs[[length(msgs) + 1]] <- list(
        role = "assistant",
        content = paste("Error:", e$message)
      )
      chat_messages(msgs)
    })

    # Hide spinner
    shinyjs::runjs("document.getElementById('chatSpinner').style.display = 'none';")
    shinyjs::runjs("document.getElementById('sendChat').disabled = false;")
  })

  # Clear chat
  observeEvent(input$clearChat, {
    chat_messages(list())
    if (!is.null(assistant())) {
      assistant()$reset_conversation()
    }
    showNotification("Chat cleared", type = "message")
  })

  # Help button
  observeEvent(input$helpBtn, {
    updateTextAreaInput(session, "chatInput", value = "help")
  })

  # Example buttons
  observeEvent(input$exampleGenerate, {
    updateTextAreaInput(session, "chatInput",
                        value = "Create a study measuring stress and anxiety in college students with daily surveys")
  })

  observeEvent(input$exampleModify, {
    updateTextAreaInput(session, "chatInput",
                        value = "Add demographic questions for age, gender, and year in school")
  })

  # Keep existing direct generation/modification code
  observeEvent(input$generateAIStudy, {
    # Your existing code...
  })

  observeEvent(input$modifyAIStudy, {
    # Your existing code...
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
