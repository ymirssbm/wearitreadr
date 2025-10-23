library(shiny)
devtools::load_all()
shiny::addResourcePath("codebook", "Codebook_RMD")

ui <- navbarPage("Navigation",
                 tabPanel("Home",
                   h1("Purpose of this tool"),
                   p("This is a human accessible tool to help pull data and generate codebooks for Wear-IT users")),

                 tabPanel("Codebook Generator",
                          p("Press the button to generate a codebook from the data you pulled down"),
                          actionButton(inputId = "generateCodebook", label = "Generate Codebook")),

                 tabPanel("Data pull",
                          p("This is where you can pull data down from Wear-IT. Just supply the study ID number of the study you want to pull data from and then click the button"),
                          numericInput(inputId = "studyID", label = "Insert Study ID", value = 0),
                          actionButton(inputId = "pullDataButton", label = "Pull Data from Wear-IT")),

                 tabPanel("Codebook",
                          uiOutput("codebook"))
)

server <- function(input, output) {

  # Generate Codebook button
  observeEvent(input$generateCodebook, {
    # Run codebook generator function
    generateCodebook(shiny = TRUE)
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

  })

  # Pull data down button
  observeEvent(input$pullDataButton, {
    print(getwd())
    data <- getStudyData(study_ID = input$StudyID)
    saveData(data)
  })



}

shinyApp(ui = ui, server = server)
