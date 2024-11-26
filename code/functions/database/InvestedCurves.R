#### InvestedCurves
# Function to compute the total investments into each asset in USD.


InvestedCurves <- function(conn, main_currency) {
  
  # "Raw" data
  dist_assets <- dbGetQuery(conn, "SELECT * FROM vDistAssets;")
  if (nrow(dist_assets) == 0) {
    return(NULL)
  }
  
  if (main_currency != "USD") {
    xrates <- dbGetQuery(
      conn      = conn,
      statement = "
        SELECT Date, Adjusted AS XRate
        FROM xrates
        WHERE Currency = ?
      ",
      params    = main_currency
    )
  }
  
  # Summing price curves and total quantities
  res <- dplyr::bind_rows(lapply(1:nrow(dist_assets), function(i) {
    prices <- dbGetQuery(
      conn,
      "
        SELECT *
        FROM vPricesUSD
        WHERE TickerSymbol = ?
      ",
      params = dist_assets[i, "TickerSymbol"]
    )
    transactions <- dbGetQuery(
      conn,
      "
        SELECT 
          a.*,
          (
            SELECT xr.Adjusted
            FROM xrates xr
            WHERE xr.Date <= a.Date
              AND xr.Currency = ?
            ORDER BY xr.Date DESC
            LIMIT 1
          ) AS XRate
        FROM vAssetsUSD a
        WHERE AssetID = ?
      ",
      params = c(main_currency, dist_assets[i, "AssetID"])
    )
    
    if (main_currency != "USD") {
      # transactions$XRate[is.na(transactions$XRate)] <- 1
      transactions$PriceTotal <- transactions$PriceTotalUSD / transactions$XRate
    } else {
      transactions$PriceTotal <- transactions$PriceTotalUSD
    }
    transactions <- transactions[, -9]
    
    res <- data.frame(Date = prices$Date, Value = 0, Quantity = 0, AcqVal = 0)
    for (t in 1:nrow(transactions)) {
      res$Value    <- res$Value + ifelse(prices$Date < transactions[t, "Date"], 0, prices$PriceUSD) * transactions[t, "Quantity"]
      res$Quantity <- res$Quantity + ifelse(prices$Date < transactions[t, "Date"], 0, transactions[t, "Quantity"])
      if (transactions[t, "Quantity"] > 0) {
        res$AcqVal <- res$AcqVal + ifelse(prices$Date < transactions[t, "Date"], 0, transactions[t, "PriceTotal"])
      } else {
        res$AcqVal <- res$AcqVal - ifelse(prices$Date < transactions[t, "Date"], 0, mean(res[nrow(res), "AcqVal"]) * transactions[t, "Quantity"])
      }
    }
    res$DisplayName = dist_assets[i, "DisplayName"]
    res$TickerSymbol = dist_assets[i, "TickerSymbol"]
    res$Type = dist_assets[i, "Type"]
    res$Group = dist_assets[i, "Group"]
    res$AssetID = dist_assets[i, "AssetID"]
    
    res
  }))
  
  # Cross rates
  if (main_currency != "USD") {
    res_dates <- data.frame(Date = unique(res$Date))
    xrates <- merge(x = xrates, y = res_dates, by.x = "Date", by.y = "Date", all = TRUE)
    na_indices <- which(is.na(xrates$XRate))
    for (i in na_indices) {
      if (i == 1) {
        next
      }
      xrates$XRate[i] <- xrates$XRate[i-1]
    }
    res <- merge(x = res, y = xrates, by = "Date", all.x = TRUE, all.y = FALSE)
    res$Value <- res$Value / res$XRate
    res <- res[, -10]
  }
  
  na.omit(res)
  
}

