#### QueryXRates
# Queries the xrates for all currencies and stores it in the database.
# Note: I simply store the entire history, as I don't want to deal with checking if the first transaction date of a new
#       asset came before the first xrate entry and to then weirdly slice around to fill the table.


QueryXRates <- function(conn) {
  # All currencies
  currencies <- unlist(dbGetQuery(conn = conn, statement = "SELECT Currency FROM currencies;"))
  
  #
  lapply(currencies, function(currency) {
    if (currency == "USD") { return(NULL) }
    
    last_date <- dbGetQuery(
      conn      = conn,
      statement = paste0("
        SELECT Date
        FROM xrates
        WHERE Currency = '", currency, "'
        ORDER BY Date DESC
        LIMIT 1;
      ")
    )[[1]]
    
    if (length(last_date) == 0) {
      prices <- tryCatch(
        {
          quantmod::getSymbols(
            Symbols = paste0(currency, "USD=X"), env = NULL
          )
        },
        error = function(cond) { return(NULL) }
      )
    } else {
      prices <- tryCatch(
        {
          quantmod::getSymbols(
            Symbols = paste0(currency, "USD=X"), env = NULL, from = format(as.Date(last_date) + 1, "%Y-%m-%d")
          )
          if ((index(prices)[nrow(prices)] == format(as.Date(last_date), "%Y-%m-%d"))) { return(NULL) }
        },
        error = function(cond) { return(NULL) }
      )
    }
    
    # Stopping if no new prices (or any prices at all) exist
    if (is.null(prices)) { return(NULL) }
    
    # Formatting to fill the table and filling the table    
    prices <- data.frame(date = as.character(format(as.Date(index(prices)), "%Y-%m-%d")), coredata(prices))
    colnames(prices) <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adjusted")
    prices$Currency <- currency
    dbWriteTable(conn = conn, name = "xrates", value = prices, append = TRUE)
  })
  
}

