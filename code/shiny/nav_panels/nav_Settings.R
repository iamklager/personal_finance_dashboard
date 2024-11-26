nav_Settings <- nav_panel(
  title = "",
  div(
    style = "display: inline-flex; border-width: thick; gap: 1.50%; align-items: center;;",
    input_switch(
      id = "in_DarkModeOn",
      label = "Dark Mode",
      value = dbGetQuery(dbConn, "select DarkModeOn from settings limit 1;")[[1]],
      width = "8.70%"
    ) |> tooltip(l_ToolTips[["DarkModeOn"]]),
    colourInput(
      inputId    = "in_ColorProfit",
      label      = "Color: Profit",
      value      = dbGetQuery(dbConn, "select ColorProfit from settings limit 1;")[[1]],
      showColour = "both",
      palette    = "square",
      width      = "8.70%"
    ) |> tooltip(l_ToolTips[["ColorProfit"]]),
    colourInput(
      inputId    = "in_ColorLoss",
      label      = "Color: Loss",
      value      = dbGetQuery(dbConn, "select ColorLoss from settings limit 1;")[[1]],
      showColour = "both",
      palette    = "square",
      width      = "8.70%"
    ) |> tooltip(l_ToolTips[["ColorLoss"]])
  ),
  div(
    style = "display: inline-flex; border-width: thick; gap: 1.50%;",
    selectizeInput(
      inputId  = "in_DateFormat",
      label    = "Date Format",
      choices  = c("yyyy-mm-dd", "mm/dd/yyyy", "dd.mm.yyyy"),
      selected = dbGetQuery(dbConn, "select DateFormat from settings limit 1;")[[1]]
    ) |> tooltip(l_ToolTips[["DateFormat"]]),
    selectizeInput(
      inputId  = "in_MainCurrency",
      label    = "Currency",
      choices  = dbGetQuery(dbConn, "select Currency from currencies;")[[1]]
    ) |> tooltip(l_ToolTips[["MainCurrency"]])
  )
)

