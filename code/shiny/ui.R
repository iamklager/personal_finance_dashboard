#### UI
# The ui...


ui <- navbarPage(
  ## Design stuff
  theme = bs_theme(
    # Base theme
    preset     = "cosmo",
    primary    = "gray"
  ),
  title = "My Finances",
  windowTitle = "My Finances",
  selected = "Summary",
  lang = "en",
  
  sidebar = sidebar(
    tags$hr(),
    tags$b("Set Date Range:"),
    div(
      style = "display: flex; gap: 20px;",
      dateInput(
        inputId   = "in_DateFrom",
        label     = "From",
        value     = dbGetQuery(dbConn, "select DateFrom from settings limit 1;")[[1]],
        min       = as.Date("1900-01-01", format = "%Y-%m-%d"),
        format    = dbGetQuery(dbConn, "select DateFormat from settings limit 1;")[[1]],
        startview = "year"
      ) |> tooltip(l_ToolTips[["DateFrom"]]),
      dateInput(
        inputId   = "in_DateTo",
        label     = "To",
        value     = Sys.Date(),
        min       = as.Date("1900-01-01", format = "%Y-%m-%d"),
        max       = Sys.Date(),
        format    = dbGetQuery(dbConn, "select DateFormat from settings limit 1;")[[1]],
        startview = "year"
      ) |> tooltip(l_ToolTips[["DateTo"]])
    ),
    div(
      style = "display: flex; gap: 20px;",
      actionButton(
        inputId = "in_EntireDateRange",
        label   = "All Time",
        width   = "50%"
      ) |> tooltip(l_ToolTips[["EntireDateRange"]]),
      actionButton(
        inputId = "in_YTD",
        label   = "YTD",
        width   = "50%"
      ) |> tooltip(l_ToolTips[["YearToDate"]])
    ),
    div(
      style = "display: flex; gap: 20px;",
      actionButton(
        inputId = "in_OneYearDateRange",
        label   = "1 Year",
        width   = "50%"
      ) |> tooltip(l_ToolTips[["OneYearDateRange"]]),
      actionButton(
        inputId = "in_ThisMonthDateRange",
        label   = "Month",
        width   = "50%"
      ) |> tooltip(l_ToolTips[["ThisMonthDateRange"]])
    ),
    #tags$br(),
    tags$hr(),
    tags$b("Download Raw Data:"),
    selectizeInput(
      inputId = "in_DownloadRawData",
      label = "Dataset:",
      choices = c("Income", "Expenses", "Assets")
    ),
    downloadButton(
      outputId = "out_DownloadRawData",
      label = "Download .csv"
    ) |> tooltip(l_ToolTips[["DownloadRawData"]])
  ),
  
  
  nav_panel(
    title = "Summary",
    layout_columns(
      col_widths = c(6, 6),
      navset_card_underline(
        full_screen = FALSE,
        title       = "Profit/Loss" |> tooltip(l_ToolTips[["PLTotal/Ratio"]]),
        height      = "435px",
        nav_panel(title = "Total", uiOutput("out_txtPLTotal")),
        nav_panel(title = "As % of Income", uiOutput("out_txtPLRatio"))
      ),
      navset_card_underline(
        full_screen = FALSE,
        title       = "Invested Income" |> tooltip(l_ToolTips[["InvSums"]]),
        height      = "435px",
        nav_panel(title = "", highchartOutput("out_InvSums", height = "100%"))
      )
    ),
    layout_columns(
      navset_card_underline(
        full_screen = TRUE,
        title       = "Profit/Loss by Source" |> tooltip(l_ToolTips[["PLSource"]]),
        height      = "435px",
        nav_panel(title = "", highchartOutput("out_hcPLSource", height = "100%"))
      ),
      navset_card_underline(
        full_screen = TRUE,
        title       = "Profit/Loss Over Time" |> tooltip(l_ToolTips[["PLMonth"]]),
        height      = "435px",
        nav_panel(title = "", highchartOutput("out_hcPLMonth", height = "100%"))
      )
    )
  ),


  nav_panel(
    title = "Income",
    layout_columns(
      navset_card_underline(
        full_screen = TRUE,
        title       = "Income by Category" |> tooltip(l_ToolTips[["IncomeCateogry"]]),
        height      = "435px",
        nav_panel(title = "", highchartOutput("out_hcIncomeCategory", height = "100%"))
      ),
      navset_card_underline(
        full_screen = TRUE,
        title       = "Income by Month" |> tooltip(l_ToolTips[["IncomeMonth"]]),
        height      = "435px",
        nav_panel(title = "", highchartOutput("out_hcIncomeMonth", height = "100%"))
      )
    ),
    navset_card_underline(
      full_screen = TRUE,
      title       = "Income by Source" |> tooltip(l_ToolTips[["IncomeSource"]]),
      height      = "435px",
      nav_panel(title = "", highchartOutput("out_hcIncomeSource", height = "100%"))
    )
  ),


  nav_panel(
    title = "Expenses",
    layout_columns(
      navset_card_underline(
        full_screen = TRUE,
        title       = "Expenses by Category" |> tooltip(l_ToolTips[["ExpensesCategory"]]),
        height      = "435px",
        nav_panel(title = "", highchartOutput("out_hcExpensesCategory", height = "100%"))
      ),
      navset_card_underline(
        full_screen = TRUE,
        title       = "Expenses by Month" |> tooltip(l_ToolTips[["ExpensesMonth"]]),
        height      = "435px",
        nav_panel(title = "", highchartOutput("out_hcExpensesMonth", height = "100%"))
      )
    ),
    navset_card_underline(
      full_screen = TRUE,
      title       = "Expenses by Source" |> tooltip(l_ToolTips[["ExpensesSource"]]),
      height      = "435px",
      nav_panel(title = "", highchartOutput("out_hcExpensesSource", height = "100%"))
    )
  ),


  nav_panel(
    title = "Assets",
    layout_columns(
      navset_card_underline(
        full_screen = TRUE,
        title       = "Asset Allocation" |> tooltip(l_ToolTips[["AssetAlloc"]]),
        height      = "435px",
        nav_panel(title = "Current Value", highchartOutput("out_hcAssetAllocCur", height = "100%")),
        nav_panel(title = "Acquisition Value", highchartOutput("out_hcAssetAllocAcq", height = "100%"))
      ),
      navset_card_underline(
        full_screen = TRUE,
        title       = "Asset Gains" |> tooltip(l_ToolTips[["AssetGains"]]),
        height      = "435px",
        nav_panel(title = "Stocks", highchartOutput("out_hcAssetGainsStock", height = "100%")),
        nav_panel(title = "Alternatives", highchartOutput("out_hcAssetGainsAlternative", height = "100%"))
      )
    ),
    navset_card_underline(
      full_screen = TRUE,
      title       = "Cumulated Asset Development" |> tooltip(l_ToolTips[["AssetDev"]]),
      height      = "435px",
      nav_panel(title = "Stocks", highchartOutput("out_hcAssetGainCurvesStock", height = "100%")),
      nav_panel(title = "Alternatives", highchartOutput("out_hcAssetGainCurvesAlternative", height = "100%"))
    )
  ),


  nav_panel(
    title = "Tracking",
    navset_card_underline(
      full_screen = FALSE,
      height      = "885px",
      nav_TrackIncome,
      nav_TrackExpenses,
      nav_TrackAssets
    )
  ),

  nav_panel(
    title = "Settings",

    navset_card_underline(
      full_screen = FALSE,
      height      = "885px",
      nav_Settings
    )
  )
  
  
)

