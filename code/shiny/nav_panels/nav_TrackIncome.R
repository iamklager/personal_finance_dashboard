nav_TrackIncome <- nav_panel(
  title = "Income" |> tooltip(l_ToolTips[["IncomeItems"]]),
  div(
    style = "display: block;",
    DT::DTOutput("out_DTIncome")
  ),
  tags$hr(),
  tags$b("Track Income:"),
  div(
    style = "display: inline-flex; border-width: thick; gap: 1.50%; justify-content: center; align-items: center;",
    dateInput(
      inputId = "in_DateIncome",
      label   = "Date",
      value   = Sys.Date(),
      max     = Sys.Date(),
      format  = dbGetQuery(dbConn, "SELECT DateFormat FROM settings LIMIT 1;")[[1]],
      width   = "8%"
    ),
    numericInput(
      inputId = "in_AmountIncome",
      label   = "Amount",
      value   = 0.00,
      min     = 0.00,
      step    = 0.50,
      width   = "8%"
    ),
    textInput(
      inputId     = "in_ProductIncome",
      label       = "Product",
      value       = "",
      placeholder = "insert income name",
      width       = "25%"
    ),
    textInput(
      inputId     = "in_SourceIncome",
      label       = "Source",
      value       = "",
      placeholder = "insert income source",
      width       = "12%"
    ),
    textInput(
      inputId     = "in_CategoryIncome",
      label       = "Category",
      value       = "",
      placeholder = "insert income category",
      width       = "12%"
    ),
    textInput(
      inputId = "in_CurrencyIncome",
      label   = "Currency",
      value   = dbGetQuery(dbConn, "SELECT MainCurrency FROM settings LIMIT 1;")[[1]],
      width   = "8%"
    ),
    input_task_button(
      id         = "in_TrackIncome",
      label      = "Track",
      label_busy = "Tracking income...",
      auto_reset = TRUE, state = "ready",
      style      = "width: 18%; height: 40px;"
    )
  ),
  tags$hr(),
  tags$b("File Upload:"),
  div(
    style = "display: inline-flex; border-width: thick; gap: 1.50%; justify-content: center; align-items: center;",
    fileInput(
      inputId = "in_FileIncome",
      label   = "Income file",
      accept  = c(".csv", ".xlsx"),
      placeholder = ".csv or .xlsx",
      width = "57.50%"
    ),
    input_task_button(
      id         = "in_AppendFileIncome",
      label      = "Append",
      label_busy = "Appending to income...",
      auto_reset = TRUE, state = "ready",
      style      = "width: 19.75%; height: 40px;"
    ),
    input_task_button(
      id         = "in_OverwriteFileIncome",
      label      = "Overwrite",
      label_busy = "Overwriting income...",
      auto_reset = TRUE, state = "ready",
      style      = "width: 19.75%; height: 40px;"
    )
  )
)