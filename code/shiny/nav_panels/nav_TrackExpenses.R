nav_TrackExpenses <- nav_panel(
  title = "Expenses" |> tooltip(l_ToolTips[["ExpensesItems"]]),
  div(
    style = "display: block;",
    DT::DTOutput("out_DTExpenses")
  ),
  tags$hr(),
  tags$b("Track Expense:"),
  div(
    style = "display: inline-flex; border-width: thick; gap: 1.50%; justify-content: center; align-items: center;",
    dateInput(
      inputId = "in_DateExpenses",
      label   = "Date",
      value   = Sys.Date(),
      max     = Sys.Date(),
      format  = dbGetQuery(dbConn, "SELECT DateFormat FROM settings LIMIT 1;")[[1]],
      width   = "8%"
    ),
    numericInput(
      inputId = "in_AmountExpenses",
      label   = "Amount",
      value   = 0.00,
      min     = 0.00,
      step    = 0.50,
      width   = "8%"
    ),
    textInput(
      inputId     = "in_ProductExpenses",
      label       = "Product",
      value       = "",
      placeholder = "insert expenses name",
      width       = "25%"
    ),
    textInput(
      inputId     = "in_SourceExpenses",
      label       = "Source",
      value       = "",
      placeholder = "insert expenses source",
      width       = "12%"
    ),
    textInput(
      inputId     = "in_CategoryExpenses",
      label       = "Category",
      value       = "",
      placeholder = "insert expenses category",
      width       = "12%"
    ),
    textInput(
      inputId = "in_CurrencyExpenses",
      label   = "Currency",
      value   = dbGetQuery(dbConn, "SELECT MainCurrency FROM settings LIMIT 1;")[[1]],
      width   = "8%"
    ),
    input_task_button(
      id         = "in_TrackExpenses",
      label      = "Track",
      label_busy = "Tracking expenses...",
      auto_reset = TRUE, state = "ready",
      style      = "width: 18%; height: 40px;"
    )
  ),
  tags$hr(),
  tags$b("File upload:"),
  div(
    style = "display: inline-flex; border-width: thick; gap: 1.50%; justify-content: center; align-items: center;",
    fileInput(
      inputId = "in_FileExpenses",
      label   = "Expenses file",
      accept  = c(".csv", ".xlsx"),
      placeholder = ".csv or .xlsx",
      width = "57.50%"
    ),
    input_task_button(
      id         = "in_AppendFileExpenses",
      label      = "Append",
      label_busy = "Appending to expenses...",
      auto_reset = TRUE, state = "ready",
      style      = "width: 19.75%; height: 40px;"
    ),
    input_task_button(
      id         = "in_OverwriteFileExpenses",
      label      = "Overwrite",
      label_busy = "Overwriting expenses...",
      auto_reset = TRUE, state = "ready",
      style      = "width: 19.75%; height: 40px;"
    )
  )
)

