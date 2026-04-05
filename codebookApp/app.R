library(shiny)
library(shinyTree)
library(shinyFiles)
library(DiagrammeR)
library(jsonlite)
rm(list = ls())
devtools::load_all(recompile = FALSE)
devtools::document()

addResourcePath("codebook", "Codebook_RMD")

ui <- navbarPage("Navigation",
                 header = tagList(
                   tags$head(includeCSS("www/shiny.css")),
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
                          numericInput(inputId = "studyID", label = "Insert Study ID", value = 0),
                          textInput(inputId = "apiToken", label = "Insert Api Token"),
                          textAreaInput(inputId = "base_URL", label = "WearIT URL", resize = "horizontal",
                                        value = "https://wearables.vmhost.psu.edu/wearables-survey/api"),
                          actionButton(inputId = "pullDataButton", label = "Pull Data from Wear-IT")),

                 # Codebooks
                 navbarMenu(
                   "Codebook",
                   tabPanel("Codebook Generator",
                            p("Select what you want included in your codebook"),
                            shinyTree("codebookOptions", checkbox = TRUE, themeIcons = FALSE, theme = "proton"),
                            textAreaInput("title", "Title", value = "", rows = 1, resize = "horizontal"),
                            textAreaInput("authors", "Authors", value = "", rows = 1, resize = "horizontal"),
                            textAreaInput("funding", "Funding", value = "", rows = 3, resize = "vertical"),
                            textAreaInput("abstract", "Abstract", value = "", rows = 5, resize = "vertical"),
                            textAreaInput("summary", "Summary", value = "", rows = 5, resize = "vertical"),
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
                     uiOutput("surveySelecter"),
                     actionButton(inputId = "generateFlowChart", label = "Generate Flow Chart"),
                     checkboxInput(inputId = "showItemID", label = "Hide Item IDs", value = FALSE),
                     uiOutput("surveyTree"),
                     hr(),
                     h4("Node Information"),
                     verbatimTextOutput("nodeInfo")
                   )
                 )
)

server <- function(input, output, session) {

  #--------------------
  # Pull Data Page
  #--------------------
  observeEvent(input$pullDataButton, {
    showNotification("Pulling Data...", type = "message")
    saveData(study_ID = input$studyID, apiToken = input$apiToken, shiny = TRUE,
             base_URL = input$base_URL, pull = TRUE)
    showNotification("Writing Data to processedData folder...", type = "message")
    showNotification("Finished!", type = "message")
  })

  #-----------------------
  # Codebook
  #-----------------------
  dataTypes <- list.files(path = "Codebook_RMD/DataTypes")
  dataTypes <- sub("\\.Rmd$", "", dataTypes)

  output$codebookOptions <- renderTree({
    list(
      "Title Page" = structure(list(
        "Name of Study" = "",
        "Authors" = "",
        "Desired Graphic" = "",
        "Funding" = ""
      )),
      "Abstract" = "",
      "Effective Summary" = "",
      "Data Types" = structure(
        setNames(as.list(rep("", length(dataTypes))), dataTypes)
      ),
      "Variable Pages" = structure(list(
        "Histograms",
        "Missingness Page",
        "Descriptives"
      ))
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
        tags$iframe(src = "codebook/Codebook.html", width = "100%", height = "800px",
                    frameborder = 0, scrolling = "auto")
      })
    }, error = function(e) {
      showNotification(paste("Error generating codebook:", e$message), type = "error")
      print(e)
    })
  })

  if (file.exists("Codebook_RMD/Codebook.html")) {
    output$codebook <- renderUI({
      tags$iframe(src = "codebook/Codebook.html", width = "100%", height = "800px",
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
        read.csv("Codebook_RMD/DataDictionary.csv")
      })
    }, error = function(e) {
      showNotification(paste("Error generating data dictionary:", e$message), type = "error")
      print(e)
    })
  })

  if (file.exists("Codebook_RMD/DataDictionary.csv")) {
    output$dataDictionary <- renderTable({
      read.csv("Codebook_RMD/DataDictionary.csv")
    })
  }

  #---------------------------------------------
  # Flowchart
  #---------------------------------------------

  # Reactive to store parsed blockmap so it's not re-parsed on every toggle
  blockMapParsed <- reactiveVal(NULL)

  output$surveySelecter <- renderUI({
    if (file.exists("Codebook_RMD/Data/blockMap.csv")) {
      blockMap <- read.csv("Codebook_RMD/Data/blockMap.csv")
      selectInput(
        inputId = "survey",
        label = "Select survey to generate flowchart for",
        choices = unique(blockMap$Survey.LongName[!is.na(blockMap$Survey.LongName)])
      )
    }
  })

  # Helper to build the renderUI tagList for the diagram
  renderMermaidUI <- function(mermaid_code) {
    tagList(
      tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"),
      tags$script(src = "https://cdn.jsdelivr.net/npm/@panzoom/panzoom@4/dist/panzoom.min.js"),
      tags$div(
        style = "width: 100%; height: 600px; border: 1px solid #ddd; overflow: hidden; position: relative;",
        tags$div(
          id = "mermaid-container",
          style = "width: 100%; height: 100%; cursor: grab;"
        )
      ),
      tags$script(HTML(sprintf("
      (function() {
        mermaid.initialize({ startOnLoad: false, theme: 'default' });

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
    blockMapParsed(parseBySurvey(survey = input$survey, shiny = TRUE))
    mermaid_code <- generateSurveyTree(blockMapParsed = blockMapParsed(), shiny = TRUE,
                                       showLabels = !input$showItemID)
    output$surveyTree <- renderUI({ renderMermaidUI(mermaid_code) })
    output$nodeInfo <- renderText({ "Click a node to see details (not available in Mermaid renderer)" })
  })

  observeEvent(input$showItemID, {
    req(blockMapParsed())
    mermaid_code <- generateSurveyTree(blockMapParsed = blockMapParsed(), shiny = TRUE,
                                       showLabels = !input$showItemID)
    output$surveyTree <- renderUI({ renderMermaidUI(mermaid_code) })
  }, ignoreInit = TRUE)

}

shinyApp(ui = ui, server = server)
