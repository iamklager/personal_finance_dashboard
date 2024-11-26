#### Server
# The server...


server <- function(input, output, session) {
  ### Price updates on first opening
  QueryPrices(dbConn)
  QueryXRates(dbConn)
  
  
  ### Reactive values
  ## Today
  rv_Today <- reactive({
    invalidateLater(24 * 60 * 60 * 1000)
    format(Sys.Date(), "%Y-%m-%d")
  })
  
  ## Income
  rv_Income      <- reactiveVal(QueryTableMainCur(
    dbConn, "income", 
    dbGetQuery(dbConn, "SELECT DateFrom FROM settings LIMIT1;")[[1]], format(Sys.Date(), "%Y-%m-%d"),
    dbGetQuery(dbConn, "SELECT MainCurrency FROM settings LIMIT 1;"[[1]])
  ))
  
  ## Expenses
  rv_Expenses      <- reactiveVal(QueryTableMainCur(
    dbConn, "expenses", 
    dbGetQuery(dbConn, "SELECT DateFrom FROM settings LIMIT1;")[[1]], format(Sys.Date(), "%Y-%m-%d"),
    dbGetQuery(dbConn, "SELECT MainCurrency FROM settings LIMIT 1;"[[1]])
  ))
  
  ## Assets
  rv_Assets        <- reactiveVal(QueryTableSimple(
    dbConn, "assets",
    dbGetQuery(dbConn, "SELECT DateFrom FROM settings LIMIT1;")[[1]], format(Sys.Date(), "%Y-%m-%d")
  ))
  rv_CurrentAssets <- reactiveVal(CurrentAssets(dbConn, format(Sys.Date(), "%Y-%m-%d")))
  rv_InvCurv       <- reactiveVal(InvestedCurves(dbConn, dbGetQuery(dbConn, "SELECT MainCurrency FROM settings LIMIT 1;")[[1]]))
  rv_InvSums       <- reactiveVal(InvestedSum(
    dbConn, 
    dbGetQuery(dbConn, "SELECT DateFrom FROM settings LIMIT1;")[[1]], format(Sys.Date(), "%Y-%m-%d"), 
    dbGetQuery(dbConn, "SELECT MainCurrency FROM settings LIMIT 1;")[[1]]
  ))
  
  
  ### Event handling
  ## Periodically
  observeEvent(rv_Today(), {
    # Writing price data
    QueryPrices(dbConn)
    QueryXRates(dbConn)
    
    # Updating YTD
    if (
      as.numeric(substr(rv_Today(), 1, 4)) >
      as.numeric(substr(
        dbGetQuery(dbConn, "SELECT DateFrom FROM settings LIMIT 1;")[[1]], 1, 4
      ))
    ) {
      dbSendQuery(dbConn, paste0(
        "UPDATE settings SET DateFrom = '", rv_Today(), "';"
      ))
    }
    
    rv_CurrentAssets(CurrentAssets(dbConn, format(Sys.Date(), "%Y-%m-%d")))
    rv_InvCurv(InvestedCurves(dbConn, input$in_MainCurrency))
    rv_InvSums(InvestedSum(
      dbConn, 
      dbGetQuery(dbConn, "SELECT DateFrom FROM settings LIMIT1;")[[1]], format(Sys.Date(), "%Y-%m-%d"), 
      input$in_MainCurrency
    ))
  })
  
  ## Settings
  # Coloring
  observeEvent(input$in_DarkModeOn, {
    toggle_dark_mode(ifelse(input$in_DarkModeOn, "dark", "light"))
    dbSendQuery(dbConn, paste0("update settings set DarkModeOn = ", input$in_DarkModeOn, ";"))
  })
  observeEvent(input$in_ColorProfit, {
    dbSendQuery(dbConn, paste0("update settings set ColorProfit = '", input$in_ColorProfit, "';"))
  })
  observeEvent(input$in_ColorLoss, {
    dbSendQuery(dbConn, paste0("update settings set ColorLoss = '", input$in_ColorLoss, "';"))
  })
  # Text rendering
  observeEvent(input$in_DateFormat, { # To-Do: Add info box stating that this does only apply after restarting the tool
    dbSendQuery(dbConn, paste0("update settings set DateFormat = '", input$in_DateFormat, "';"))
  })
  # Currency 
  observeEvent(input$in_MainCurrency, {
    dbSendQuery(dbConn, paste0("update settings set MainCurrency = '", input$in_MainCurrency, "';"))
    
    rv_Income(QueryTableMainCur(dbConn, "income", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    rv_Expenses(QueryTableMainCur(dbConn, "expenses", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    rv_InvCurv(InvestedCurves(dbConn, input$in_MainCurrency))
    rv_InvSums(InvestedSum(dbConn, format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
  })
  
  
  ## Tracking
  # Income
  observeEvent(input$in_TrackIncome, {
    if (input$in_AmountIncome == 0) {
      showNotification(ui = "Cannot track items of value 0.", type = "error")
      return(NULL)
    }
    TrackIncExp(
      dbConn, "income", format(as.Date(input$in_DateIncome), "%Y-%m-%d"), 
      input$in_AmountIncome, input$in_ProductIncome, input$in_SourceIncome, 
      input$in_CategoryIncome, input$in_CurrencyIncome
    )
    rv_Income(QueryTableMainCur(dbConn, "income", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    updateNumericInput(inputId = "in_AmountIncome", value = 0)
    updateTextInput(inputId = "in_ProductIncome", value = "")
    updateTextInput(inputId = "in_SourceIncome", value = "")
    updateTextInput(inputId = "in_CategoryIncome", value = "")
    
    showNotification(ui = "Successfully tracked income.", type = "default")
  })
  observeEvent(input$in_AppendFileIncome, {
    file <- input$in_FileIncome
    if (length(file) == 0) {
      showNotification(ui = "No file selected.", type = "error")
      return(NULL)
    }
    ext <- tools::file_ext(file$name)
    if (!(ext %in% c("csv", "xlsx"))) {
      showNotification(ui = "Invalid file extension.", type = "error")
      return(NULL)
    }
    df <- switch(EXPR = ext, csv = read.csv(file$datapath), xlsx = readxl::read_xlsx(file$datapath))
    if (!all(colnames(df) == c("Date", "Amount", "Product", "Source","Category", "Currency"))) {
      showNotification(ui = "File columns do not match.", type = "error")
      return(NULL)
    }
    df$Date <- format(as.Date(df$Date), "%Y-%m-%d")
    Append2Table(dbConn, "income", df)
    rv_Income(QueryTableMainCur(dbConn, "income", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    showNotification(ui = "Appended income.", type = "default")
  })
  observeEvent(input$in_OverwriteFileIncome, {
    file <- input$in_FileIncome
    if (length(file) == 0) {
      showNotification(ui = "No file selected.", type = "error")
      return(NULL)
    }
    ext <- tools::file_ext(file$name)
    if (!(ext %in% c("csv", "xlsx"))) {
      showNotification(ui = "Invalid file extension.", type = "error")
      return(NULL)
    }
    df <- switch(EXPR = ext, csv = read.csv(file$datapath), xlsx = readxl::read_xlsx(file$datapath))
    if (!all(colnames(df) == c("Date", "Amount", "Product", "Source","Category", "Currency"))) {
      showNotification(ui = "File columns do not match.", type = "error")
      return(NULL)
    }
    df$Date <- format(as.Date(df$Date), "%Y-%m-%d")
    OverWriteTable(dbConn, "income", df)
    rv_Income(QueryTableMainCur(dbConn, "income", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    showNotification(ui = "Overwrote income.", type = "default")
  })
  # Expenses
  observeEvent(input$in_TrackExpenses, {
    if (input$in_AmountExpenses == 0) {
      showNotification(ui = "Cannot track items of value 0.", type = "error")
      return(NULL)
    }
    TrackIncExp(
      dbConn, "expenses", format(as.Date(input$in_DateExpenses), "%Y-%m-%d"), 
      input$in_AmountExpenses, input$in_ProductExpenses, input$in_SourceExpenses, 
      input$in_CategoryExpenses, input$in_CurrencyExpenses
    )
    rv_Expenses(QueryTableMainCur(dbConn, "expenses", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    updateNumericInput(inputId = "in_AmountExpenses", value = 0)
    updateTextInput(inputId = "in_ProductExpenses", value = "")
    updateTextInput(inputId = "in_SourceExpenses", value = "")
    updateTextInput(inputId = "in_CategoryExpenses", value = "")
    
    showNotification(ui = "Successfully tracked expenses.", type = "default")
  })
  observeEvent(input$in_AppendFileExpenses, {
    file <- input$in_FileExpenses
    if (length(file) == 0) {
      showNotification(ui = "No file selected.", type = "error")
      return(NULL)
    }
    ext <- tools::file_ext(file$name)
    if (!(ext %in% c("csv", "xlsx"))) {
      showNotification(ui = "Invalid file extension.", type = "error")
      return(NULL)
    }
    df <- switch(EXPR = ext, csv = read.csv(file$datapath), xlsx = readxl::read_xlsx(file$datapath))
    if (!all(colnames(df) == c("Date", "Amount", "Product", "Source","Category", "Currency"))) {
      showNotification(ui = "File columns do not match.", type = "error")
      return(NULL)
    }
    df$Date <- format(as.Date(df$Date), "%Y-%m-%d")
    Append2Table(dbConn, "expenses", df)
    rv_Expenses(QueryTableMainCur(dbConn, "expenses", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    showNotification(ui = "Appended expenses.", type = "default")
  })
  observeEvent(input$in_OverwriteFileExpenses, {
    file <- input$in_FileExpenses
    if (length(file) == 0) {
      showNotification(ui = "No file selected.", type = "error")
      return(NULL)
    }
    ext <- tools::file_ext(file$name)
    if (!(ext %in% c("csv", "xlsx"))) {
      showNotification(ui = "Invalid file extension.", type = "error")
      return(NULL)
    }
    df <- switch(EXPR = ext, csv = read.csv(file$datapath), xlsx = readxl::read_xlsx(file$datapath))
    if (!all(colnames(df) == c("Date", "Amount", "Product", "Source","Category", "Currency"))) {
      showNotification(ui = "File columns do not match.", type = "error")
      return(NULL)
    }
    df$Date <- format(as.Date(df$Date), "%Y-%m-%d")
    OverWriteTable(dbConn, "expenses", df)
    rv_Expenses(QueryTableMainCur(dbConn, "expenses", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    showNotification(ui = "Overwrote expenses.", type = "default")
  })
  # Assets
  observeEvent(input$in_TrackAsset, {
    if (input$in_QuantityAsset == 0) {
      showNotification(ui = "Cannot track a quantity of 0.", type = "error")
      return(NULL)
    }
    if (input$in_TickerSymbolAsset == "") {
      showNotification(ui = "Cannot track an asset without a ticker symbol.", type = "error")
      return(NULL)
    }
    TrackAsset(
      dbConn, input$in_TypeAsset, input$in_GroupAsset, input$in_TickerSymbolAsset, 
      input$in_DisplayNameAsset, format(as.Date(input$in_DateAsset), "%Y-%m-%d"), 
      input$in_QuantityAsset, input$in_PriceTotalAsset, input$in_TransTypeAsset, 
      input$in_TransCurrencyAsset, input$in_SourceCurrencyAsset
    )
    rv_Assets(QueryTableSimple(dbConn, "assets", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    
    QueryPrices(dbConn)
    AddCurrencies(dbConn, c(input$in_TransCurrencyAsset, input$in_SourceCurrencyAsset))
    QueryXRates(dbConn)

    rv_CurrentAssets(CurrentAssets(dbConn, format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    rv_InvCurv(InvestedCurves(dbConn, input$in_MainCurrency))
    rv_InvSums(InvestedSum(dbConn, format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    updateTextInput(inputId = "in_DisplayNameAsset", value = "")
    updateNumericInput(inputId = "in_QuantityAsset", value = 0)
    updateNumericInput(inputId = "in_PriceTotalAsset", value = 0)
    updateTextInput(inputId = "in_TickerSymbolAsset", value = "")
    updateTextInput(inputId = "in_GroupAsset", value = "")
    updateTextInput(inputId = "in_TransCurrencyAsset", value = "")
    updateTextInput(inputId = "in_SourceCurrencyAsset", value = "")
    
    showNotification(ui = "Successfully tracked assets.", type = "default")
  })
  observeEvent(input$in_AppendFileAssets, {
    file <- input$in_FileAssets
    if (length(file) == 0) {
      showNotification(ui = "No file selected.", type = "error")
      return(NULL)
    }
    ext <- tools::file_ext(file$name)
    if (!(ext %in% c("csv", "xlsx"))) {
      showNotification(ui = "Invalid file extension.", type = "error")
      return(NULL)
    }
    df <- switch(EXPR = ext, csv = read.csv(file$datapath), xlsx = readxl::read_xlsx(file$datapath))
    if (!all(colnames(df) == c(
      "Date", "DisplayName", "Quantity",	"PriceTotal",	"TickerSymbol",	"Type",	"Group",	"TransactionType",	
      "TransactionCurrency",	"SourceCurrency"
      ))) {
      showNotification(ui = "File columns do not match.", type = "error")
      return(NULL)
    }
    df$Date <- format(as.Date(df$Date), "%Y-%m-%d")
    Append2Table(dbConn, "assets", df)
    rv_Assets(QueryTableSimple(dbConn, "assets", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    
    QueryPrices(dbConn)
    AddCurrencies(dbConn, unique(c(df$TransactionCurrency, df$SourceCurrency)))
    QueryXRates(dbConn)
    
    rv_CurrentAssets(CurrentAssets(dbConn, format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    rv_InvCurv(InvestedCurves(dbConn, input$in_MainCurrency))
    rv_InvSums(InvestedSum(dbConn, format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    showNotification(ui = "Appended assets.", type = "default")
  })
  observeEvent(input$in_OverwriteFileAssets, {
    file <- input$in_FileAssets
    if (length(file) == 0) {
      showNotification(ui = "No file selected.", type = "error")
      return(NULL)
    }
    ext <- tools::file_ext(file$name)
    if (!(ext %in% c("csv", "xlsx"))) {
      showNotification(ui = "Invalid file extension.", type = "error")
      return(NULL)
    }
    df <- switch(EXPR = ext, csv = read.csv(file$datapath), xlsx = readxl::read_xlsx(file$datapath))
    if (!all(colnames(df) == c(
      "Date", "DisplayName", "Quantity",	"PriceTotal",	"TickerSymbol",	"Type",	"Group",	"TransactionType",	
      "TransactionCurrency",	"SourceCurrency"
    ))) {
      showNotification(ui = "File columns do not match.", type = "error")
      return(NULL)
    }
    df$Date <- format(as.Date(df$Date), "%Y-%m-%d")
    OverWriteTable(dbConn, "assets", df)
    rv_Assets(QueryTableSimple(dbConn, "assets", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    
    QueryPrices(dbConn)
    AddCurrencies(dbConn, unique(c(df$TransactionCurrency, df$SourceCurrency)))
    QueryXRates(dbConn)
    
    rv_CurrentAssets(CurrentAssets(dbConn, format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    rv_InvCurv(InvestedCurves(dbConn, input$in_MainCurrency))
    rv_InvSums(InvestedSum(dbConn, format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    
    showNotification(ui = "Overwrote assets.", type = "default")
  })
  
  ## Date selection
  observeEvent(input$in_DateFrom, {
    # Income
    rv_Income(QueryTableMainCur(dbConn, "income", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    # Expenses
    rv_Expenses(QueryTableMainCur(dbConn, "expenses", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    # Assets
    rv_Assets(QueryTableSimple(dbConn, "assets", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    
    rv_InvSums(InvestedSum(dbConn, format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
  })
  observeEvent(input$in_DateTo, {
    # Income
    rv_Income(QueryTableMainCur(dbConn, "income", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    # Expenses
    rv_Expenses(QueryTableMainCur(dbConn, "expenses", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
    # Assets
    rv_Assets(QueryTableSimple(dbConn, "assets", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d")))
    
    rv_CurrentAssets(CurrentAssets(dbConn, input$in_DateTo))
    rv_InvSums(InvestedSum(dbConn, format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency))
  })
  observeEvent(input$in_EntireDateRange, {
    updateDateInput(inputId = "in_DateFrom", value = FirstDate(dbConn))
    updateDateInput(inputId = "in_DateTo", value = rv_Today())
  })
  observeEvent(input$in_YTD, {
    updateDateInput(inputId = "in_DateFrom", value = dbGetQuery(dbConn, "select DateFrom from settings limit 1;")[[1]])
    updateDateInput(inputId = "in_DateTo", value = rv_Today())
  })
  observeEvent(input$in_OneYearDateRange, {
    from <- as.POSIXlt(Sys.Date())
    from$year <- from$year - 2
    from <- format(as.Date(from), "%Y-%m-%d")
    updateDateInput(inputId = "in_DateFrom", value = from)
    updateDateInput(inputId = "in_DateTo", value = rv_Today())
  })
  observeEvent(input$in_ThisMonthDateRange, {
    updateDateInput(inputId = "in_DateFrom", value = format(as.Date(rv_Today()), "%Y-%m-01"))
    updateDateInput(inputId = "in_DateTo", value = rv_Today())
  })
  
  
  ### Outputs
  ## Download thingy
  output$out_DownloadRawData <- downloadHandler(
    filename = function() {
      paste0(tolower(input$in_DownloadRawData), ".csv", sep = "")
    },
    content = function(file) {
      csv <- dbGetQuery(
        conn = dbConn,
        statement = paste0(
          "SELECT * FROM ", tolower(input$in_DownloadRawData), " ",
          "WHERE Date BETWEEN '", as.character(format(as.Date(input$in_DateFrom), "%Y-%m-%d")), "' AND '",
          as.character(format(as.Date(input$in_DateTo), "%Y-%m-%d")), "'",
          "ORDER BY Date ASC;"
        )
      )
      write.csv(csv, file, row.names = FALSE)
    }
  )
  
  ## Tracking
  # Income
  output$out_DTIncome <- DT::renderDT({
    df <- rv_Income()
    df$Date <- as.Date(df$Date)
    DT::datatable(df, options = list(paging = TRUE, pageLength = 7))
  })
  # Expenses
  output$out_DTExpenses <- DT::renderDT({
    df <- rv_Expenses()
    df$Date <- as.Date(df$Date)
    DT::datatable(df, options = list(paging = TRUE, pageLength = 7))
  })
  # Assets
  output$out_DTAssets <- DT::renderDT({
    df <- rv_Assets()
    df$Date <- as.Date(df$Date)
    DT::datatable(df, options = list(paging = TRUE, pageLength = 5))
  })
  
  ## Income
  output$out_hcIncomeCategory <- renderHighchart({
    hcIncExpByCategory(rv_Income(), input$in_MainCurrency, input$in_DarkModeOn)
  })
  output$out_hcIncomeMonth <- renderHighchart({
    hcIncExpByMonth(rv_Income(), input$in_ColorProfit, input$in_MainCurrency, input$in_DarkModeOn)
  })
  output$out_hcIncomeSource <- renderHighchart({
    hcIncExpBySource(rv_Income(), input$in_MainCurrency, input$in_DarkModeOn)
  })
  
  ## Expenses
  output$out_hcExpensesCategory <- renderHighchart({ hcIncExpByCategory(rv_Expenses(), input$in_MainCurrency, input$in_DarkModeOn) })
  output$out_hcExpensesMonth    <- renderHighchart({ hcIncExpByMonth(rv_Expenses(), input$in_ColorLoss, input$in_MainCurrency, input$in_DarkModeOn) })
  output$out_hcExpensesSource   <- renderHighchart({ hcIncExpBySource(rv_Expenses(), input$in_MainCurrency, input$in_DarkModeOn)})
  
  ## Assets
  output$out_hcPlaceHolder <- renderHighchart({})
  output$out_hcAssetAllocAcq <- renderHighchart({ hcAssetAllocAcq(rv_InvCurv(), rv_CurrentAssets(), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency, input$in_DarkModeOn) })
  output$out_hcAssetAllocCur <- renderHighchart({ hcAssetAllocCur(rv_InvCurv(), rv_CurrentAssets(), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_MainCurrency, input$in_DarkModeOn) })
  output$out_hcAssetGainsStock <- renderHighchart({ hcAssetGains(rv_InvCurv(), rv_CurrentAssets(), "Stock", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_DarkModeOn) })
  output$out_hcAssetGainsAlternative <- renderHighchart({ hcAssetGains(rv_InvCurv(), rv_CurrentAssets(), "Alternative", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_DarkModeOn) })
  output$out_hcAssetGainCurvesStock <- renderHighchart({ hcAssetGainCurves(rv_InvCurv(), "Stock", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_DarkModeOn) })
  output$out_hcAssetGainCurvesAlternative <- renderHighchart({ hcAssetGainCurves(rv_InvCurv(), "Alternative", format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), input$in_DarkModeOn) })
  
  ## Summary
  output$out_txtPLTotal <- renderUI({ 
    txtPLTotal(
      rv_Income(), rv_Expenses(), rv_InvCurv(), format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), 
      input$in_MainCurrency, input$in_ColorProfit, input$in_ColorLoss
    )
  })
  output$out_txtPLRatio <- renderUI({
    txtPLRatio(
      rv_Income(), rv_Expenses(), rv_InvCurv(), format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), 
      input$in_ColorProfit, input$in_ColorLoss
    )
  })
  output$out_InvSums <- renderHighchart({
    hcInvSumMonth(
      rv_InvSums(), rv_Income(), input$in_MainCurrency, input$in_DarkModeOn
    )
  })
  output$out_hcPLSource <- renderHighchart({
    hcPLSources(
      rv_Income(), rv_Expenses(), rv_InvCurv(), format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), 
      input$in_MainCurrency, input$in_DarkModeOn
    )
  })
  output$out_hcPLMonth  <- renderHighchart({
    hcPLMonth(
      rv_Income(), rv_Expenses(), rv_InvCurv(), format(as.Date(input$in_DateFrom), "%Y-%m-%d"), format(as.Date(input$in_DateTo), "%Y-%m-%d"), 
      input$in_MainCurrency, input$in_DarkModeOn, 
      input$in_ColorProfit, input$in_ColorLoss
    )
  })
  
}

