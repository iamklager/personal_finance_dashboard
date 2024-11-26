#### Main
# Run this file to start the app.


### Libraries ----
library(DBI)
library(RSQLite)
library(readxl)
library(quantmod)
library(highcharter)
library(shiny)
library(bslib)
library(bsicons)
library(DT)
library(colourpicker)


### Sourcing files ----
## Database setup
source("code/database/db_setup.R")

## Functions
invisible(lapply(list.files("code/functions", pattern = ".R", full.names = T, recursive = T), function(file) { source(file) }))

## Shiny
source("code/shiny/tooltips.R")
invisible(lapply(list.files("code/shiny/nav_panels", pattern = ".R", full.names = T, recursive = T), function(file) { source(file) }))
source("code/shiny/ui.R")
source("code/shiny/server.R")


### Run the app ----
shinyApp(ui = ui, server = server)

