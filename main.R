#### Main
# Run this file to start the app.


### Functions ----
invisible(lapply(
  list.files("code/functions", pattern = ".R", full.names = T, recursive = T), 
  function(file) {
    source(file)
  }
))


### Libraries ----
CheckDependencies(
  dependencies = c(
    "DBI", "RSQLite", "readxl", "quantmod", "highcharter", 
    "shiny", "bslib", "DT", "colourpicker"
  ),
  install_dependencies = TRUE
)


### Database setup ----
source("code/database/db_setup.R")


### Shiny ----
source("code/shiny/tooltips.R")
invisible(lapply(
  list.files("code/shiny/nav_panels", pattern = ".R", full.names = T, recursive = T), 
  function(file) {
    source(file)
  }
))
source("code/shiny/ui.R")
source("code/shiny/server.R")


### Run the app ----
shinyApp(ui = ui, server = server)

