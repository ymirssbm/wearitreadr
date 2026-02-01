library(shiny)
library(shinyTree)
library(shinyFiles)
require(visNetwork)
rm(list = ls())
devtools::load_all(recompile = FALSE)
devtools::document()

addResourcePath("codebook", "Codebook_RMD")


ui <- navbarPage("Navigation",
                 #theme = shinythemes::shinytheme("flatly"), # optional base theme
                 tags$head(
                   includeCSS("www/shiny.css")
                 ),



                 # This is just a force it not to make a card behind the data dictionary viewer
                 # Definitely a better way but this is temp default
                 tags$script(HTML("
                    $(document).on('shiny:connected', function() {
                      // Find the tab with text 'Data Dictionary Viewer'
                      var ddvTab = $('a:contains(\"Data Dictionary Viewer\")').attr('href');
                      // Remove the default tab-pane styles when it is shown
                      $(ddvTab).css({
                        'background-color': 'transparent',
                        'margin': '0',
                        'padding': '0',
                        'border-radius': '0',
                        'box-shadow': 'none'
                      });
                    });
                  ")),


                 # Home informational page
                 tabPanel("Home",
                   h1("Purpose of this tool"),
                   p("This is a human accessible tool to help pull data and generate codebooks for Wear-IT users")),


                 # Pull data page
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

                   # Codebook generator page
                   tabPanel("Codebook Generator",

                            # Codebook display options
                            p("Select what you want included in your codebook"),
                            shinyTree("codebookOptions", checkbox = TRUE, themeIcons = FALSE, theme = "proton"),

                            # Text Input Buttons
                            textAreaInput("title", "Title",
                                          value = "",
                                          rows = 1, resize = "horizontal"),
                            textAreaInput("authors", "Authors",
                                          value = "",
                                          rows = 1, resize = "horizontal"),
                            textAreaInput("funding", "Funding",
                                          value = "",
                                          rows = 3, resize = "vertical"),
                            textAreaInput("abstract", "Abstract",
                                          value = "",
                                          rows = 5, resize = "vertical"),
                            textAreaInput("summary", "Summary",
                                          value = "",
                                          rows = 5, resize = "vertical"),


                            # Generate Codebook Button
                            p("Press the button to generate a codebook from the data you pulled down"),
                            actionButton(inputId = "generateCodebook", label = "Generate Codebook")),


                   # Codebook viewer page
                   tabPanel("Codebook Viewer",
                            uiOutput("codebook")),
                 ),


                 # Data Dictionary
                 navbarMenu(
                   "Data Dictionary",

                   # Generator page
                   tabPanel("Data Dictionary Generator",

                            # Generate Data Dictionary Button
                            p("Press the button to generate a data dictionary from the data you pulled down"),
                            actionButton(inputId = "generateDataDictionary", label = "Generate Data Dictionary")),

                   # Viewer Page
                   tabPanel(
                     "Data Dictionary Viewer",
                     div(class = "no-tab-style",
                         uiOutput("dataDictionary"))
                    )
                 ),

                 # Flowchart page
                 tabPanel(
                   "Flowchart",
                   fluidPage(
                     uiOutput("surveySelecter"),
                     actionButton(inputId = "generateFlowChart", label = "Generate Flow Chart"),
                     visNetworkOutput("surveyTree"))
                 )


)


server <- function(input, output) {


  #--------------------
  # Pull Data Page
  # -------------------

  # Pull data down button
  observeEvent(input$pullDataButton, {
    print(getwd())
    showNotification("Pulling Data...", type = "message")
    saveData(study_ID = input$studyID, apiToken = input$apiToken, shiny = TRUE,
                         base_URL = input$base_URL)
    showNotification("Writing Data to processedData folder...", type = "message")
    showNotification("Finished!", type = "message")
  })


  #-----------------------
  # Codebook
  # ----------------------

  # Grab Data types
  dataTypes <- list.files(path = "Codebook_RMD/DataTypes")
  dataTypes <- sub("\\.Rmd$", "", dataTypes)


  # Render tree
  output$codebookOptions <- renderTree({
    list(
      "Title Page" = structure(
        list(
          "Name of Study" = "",
          "Authors" = "",
          "Desired Graphic" = "",
          "Funding" = ""
        )
      ),
      "Abstract" = "",
      "Effective Summary" = "",
      "Data Types" = structure(
        setNames(as.list(rep("", length(dataTypes))), dataTypes)
      ),
      "Variable Pages" = structure(
        list(
          "Histograms",
          "Missingness Page",
          "Descriptives"

        )
      )
    )
  })

  # Generate Codebook button
  observeEvent(input$generateCodebook, {

    # Grab params to be knitted from shinyTree
    codebookOptions <- tolower(get_selected(input$codebookOptions, format = "names"))
    print(codebookOptions)  # <-- see what’s actually being captured

    # Run codebook generator function
    # Try catch if successful...
    tryCatch({
      showNotification("Generating codebook...", type = "message")
      generateCodebook(shiny = TRUE,
                       codebookChunkDisplayOptions = codebookOptions,
                       # Free text inputs
                       title = input$title,
                       authors = input$authors,
                       funding = input$funding,
                       abstract = input$abstract,
                       summary = input$summary
                       )
      showNotification("Codebook Generation Complete!", type = "message")

      # Display knitted html to render in the app
      output$codebook <- renderUI({
        tags$iframe(
          src = "codebook/Codebook.html",
          width = "100%",
          height = "800px",
          frameborder = 0,
          scrolling = "auto"
        )
      })
    # If error
    }, error = function(e) {
      # Display error msg
      showNotification(paste("Error generating codebook:", e$message), type = "error")
      cat("Error in generateCodebook():\n")
      print(e)
      }
    )
  })

  # Render Codebook if it exists on launch
  if (file.exists("Codebook_RMD/Codebook.html")) {
  output$codebook <- renderUI({
    tags$iframe(
      src = "codebook/Codebook.html",
      width = "100%",
      height = "800px",
      frameborder = 0,
      scrolling = "auto"
    )
  })
  # If no codebook exists, tell user to generate one
  } else {
    showNotification("No Codebook has been generated. Press 'Generate Codebook' to generate one.", type = "message")
  }



  #---------------------------------------------
  # Data Dictionary (mirrors flow of codebook)
  # --------------------------------------------

  # Generate Data Dictionary button
  observeEvent(input$generateDataDictionary, {

    # Run data dictionary generator function
    # Try catch if successful...
    tryCatch({
      showNotification("Generating data dictionary...", type = "message")
      generateDataDictionary(shiny = TRUE)
      showNotification("data dictionary Generation Complete!", type = "message")

      # Display knitted html to render in the app
      output$dataDictionary <- renderTable({
        read.csv("Codebook_RMD/DataDictionary.csv")
      })

      # If error
    }, error = function(e) {
      # Display error msg
      showNotification(paste("Error generating data dictionary:", e$message), type = "error")
      cat("Error in generateDataDictionary():\n")
      print(e)
    }
    )
  })


  # Render Data Dictionary if it exists on launch
  if (file.exists("Codebook_RMD/DataDictionary.csv")) {
    output$dataDictionary <- renderTable({
      read.csv("Codebook_RMD/DataDictionary.csv")
    })
  }

  #---------------------------------------------
  # Flowchart builder
  # --------------------------------------------

  output$surveySelecter <- renderUI({

    if (file.exists("Codebook_RMD/Data/blockMap.csv")) {
      blockMap <- read.csv("Codebook_RMD/Data/blockMap.csv")
    }

    selectInput(
      inputId = "survey",
      label = "Select survey to generate flowchart for",
      choices = unique(blockMap$Survey.LongName[!is.na(blockMap$Survey.LongName)])
    )

  })

  observeEvent(input$generateFlowChart, {

    blockMap <- parseBySurvey(survey = input$survey, shiny = TRUE)
    output$surveyTree <- renderVisNetwork({
      generateSurveyTree(blockMap = blockMap, shiny = TRUE)
    })
  })



}

shinyApp(ui = ui, server = server)

