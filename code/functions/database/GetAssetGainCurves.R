#### GetAssetGainCurves
# Function to get the cumulated asset gain curves.


GetAssetGainCurves <- function(conn, from, to) {
  from <- as.character(from)
  to  <- as.character(to)
  assets <- dbGetQuery(
    conn = conn, 
    statement = paste0("
      SELECT *
      FROM assets
      WHERE Date < '", to, "'
      ORDER BY Date ASC;
    ")
  )
  price_data <- dbGetQuery(
    conn = conn, 
    statement = paste0("
      SELECT *
      FROM price_data
      WHERE Date < '", to, "'
      ORDER BY Date ASC;
    ")
  )
  
  assets$id <- apply(assets[, c("DisplayName", "TickerSymbol", "Type", "Group")], 1, paste, collapse = "-")
  ids <- unique(assets$id)
  
  res <- dplyr::bind_rows(lapply(ids, function(id) {
    transactions <- assets[assets$id == id, ]
    prices <- price_data[price_data$TickerSymbol == transactions[1, "TickerSymbol"], c("Date", "Adjusted")]
    
    res <- data.frame(
      Date  = prices$Date,
      Price = 0,
      Quant = 0
    )
    
    for (i in 1:nrow(transactions)) {
      new_prices <- ifelse(prices$Date < transactions[i, "Date"], 0, prices$Adjusted)
      new_prices <- new_prices / new_prices[which(prices$Date >= max(from, transactions[i, "Date"]))[1]]
      new_prices <- new_prices * transactions[i, "Quantity"]
      res$Quant  <- res$Quant + ifelse(res$Date < transactions[i, "Date"], 0, ifelse(transactions[i, "TransactionType"] == "Buy", 1, 0) * transactions[i, "Quantity"])
      res$Price  <- res$Price + ifelse(transactions[i, "TransactionType"] == "Buy", 1, 0) * new_prices
    }
    res$Price <- res$Price / res$Quant
    res <- res[res$Date >= from, ]
    res$DisplayName  <- transactions$DisplayName[1]
    res$TickerSymbol <- transactions$TickerSymbol[1]
    res$Type  <- transactions$Type[1]
    res$Group  <- transactions$Group[1]
    
    res[, c("Date", "Price", "DisplayName", "TickerSymbol", "Type", "Group")]
  }))
  
  res$Date <- as.Date(res$Date)
  res$Price <- res$Price * 100
  
  res
}


