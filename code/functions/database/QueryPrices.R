#### QueryPrices
# Function to query prices from Yahoo-Finance and store them in the database.


QueryPrices <- function(conn) {
  
  # All assets
  dist_assets <- dbGetQuery(
    conn = conn,
    statement = "
      SELECT *
      FROM vDistAssets;
    "
  )
  
  # Stopping if no assets exist
  if (nrow(dist_assets) == 0) { return(NULL) }
  
  # This is stupid but it works kinda sexy? kind off??
  lapply(1:nrow(dist_assets), function(i) {
    
    asset_id      <- dist_assets[i, "AssetID"]
    ticker_symbol <- dist_assets[i, "TickerSymbol"]
    asset_quant   <- dist_assets[i, "TotalQuantity"]
    source_curr   <- dist_assets[i, "SourceCurrency"]
    
    # Dates of the first and last transaction
    transaction_dates <- unlist(dbGetQuery(
      conn = conn, 
      statement = paste0("
        WITH FirstLast AS (
        	SELECT
        		Date,
        		ROW_NUMBER() OVER (ORDER BY Date ASC) AS RowAsc,
        		ROW_NUMBER() OVER (ORDER BY Date DESC) AS RowDesc,
        		concat(
              DisplayName, '_',
              TickerSymbol, '_',
              Type, '_',
              [Group], '_',
              TransactionCurrency
            ) AS AssetID
        	FROM assets
        	WHERE AssetID = '", asset_id, "'
        )
        
        SELECT
        	MAX(CASE WHEN RowAsc = 1 THEN Date END) As FirstDate,
        	MAX(CASE WHEN RowDesc = 1 THEN Date END) AS LastDate
        FROM FirstLast;
      ")
    ))
    
    # Last date in the price_data table
    last_date <- dbGetQuery(
      conn = conn,
      statement = paste0("
      SELECT Date
      FROM price_data
      WHERE TickerSymbol = '", ticker_symbol, "'
      ORDER BY Date DESC
      LIMIT 1;
      ")
    )[[1]]
    
    # A very ugly condition tree to query prices if they don't exist
    if (length(last_date) == 0) {
      if (asset_quant == 0) {
        prices <- tryCatch(
          {
            prices <- quantmod::getSymbols(
              env     = NULL,
              Symbols = ticker_symbol, 
              from    = transaction_dates[1], 
              to      = transaction_dates[2]
            )
          }, 
          error = function(cond) { NULL }
        )
      } else {
        prices <- tryCatch(
          {
            quantmod::getSymbols(
              env     = NULL,
              Symbols = ticker_symbol, 
              from    = as.Date(transaction_dates[1])
            )
          },
          error = function(cond) { NULL}
        )
      }
    } else {
      if (asset_quant == 0) {
        if (last_date != transaction_dates[2]) {
          prices <- tryCatch(
            {
              foo <- quantmod::getSymbols(
                env     = NULL,
                Symbols = ticker_symbol, 
                from    = format(as.Date(last_date) + 1, "%Y-%m-%d"),
                to      = transaction_dates[2]
              )
              if ((index(foo)[nrow(foo)] == format(as.Date(last_date), "%Y-%m-%d"))) { return(NULL) }
              foo
            }, 
            error = function(cond) { NULL }
          )
        } else {
          prices <- NULL
        }
      } else {
        prices <- tryCatch(
          {
            foo <- quantmod::getSymbols(
              env     = NULL,
              Symbols = ticker_symbol, 
              from    = format(as.Date(last_date) + 1, "%Y-%m-%d")
            )
            if ((index(foo)[nrow(foo)] == format(as.Date(last_date), "%Y-%m-%d"))) { return(NULL) }
            foo
          }, 
          error = function(cond) { NULL }
        )
      }
    }
    
    # Stopping if no new prices (or any prices at all) exist
    if (is.null(prices)) { return(NULL) }
    
    # Formatting to fill the table and filling the table    
    prices <- data.frame(date = as.character(format(as.Date(index(prices)), "%Y-%m-%d")), coredata(prices))
    colnames(prices) <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adjusted")
    prices$TickerSymbol   <- ticker_symbol
    prices$SourceCurrency <- source_curr
    dbWriteTable(conn = conn, name = "price_data", value = prices, append = TRUE)
  })
}

