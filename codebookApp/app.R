 .rs.restartR()
library(shiny)
library(shinyTree)
library(shinyFiles)
rm(list = ls())
devtools::load_all()
shiny::addResourcePath("codebook", "Codebook_RMD")

ui <- navbarPage("Navigation",

                 # Home informational page
                 tabPanel("Home",
                   h1("Purpose of this tool"),
                   p("This is a human accessible tool to help pull data and generate codebooks for Wear-IT users")),


                 # Pull data page
                 tabPanel("Data pull",
                          p("This is where you can pull data down from Wear-IT. Just supply the study ID number of the study you want to pull data from and then click the button"),
                          numericInput(inputId = "studyID", label = "Insert Study ID", value = 0),
                          textInput(inputId = "apiToken", label = "Insert Api Token"),
                          actionButton(inputId = "pullDataButton", label = "Pull Data from Wear-IT")),


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
                 tabPanel("Codebook",
                          uiOutput("codebook"))
)

server <- function(input, output) {


  #--------------------
  # Pull Data Page
  # -------------------

  # Pull data down button
  observeEvent(input$pullDataButton, {
    print(getwd())
    showNotification("Pulling Data...", type = "message")
    data <- getStudyDataShiny(study_ID = input$studyID, apiToken = input$apiToken)
    showNotification("Writing Data to processedData folder...", type = "message")
    saveData(data)
    showNotification("Finished!", type = "message")
  })


  #-----------------------
  # Generate Codebook Page
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

  if (file.exists("Codebook_RMD/codebook.html")) {
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


}

shinyApp(ui = ui, server = server)

