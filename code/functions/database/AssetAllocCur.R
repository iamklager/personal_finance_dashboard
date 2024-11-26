#### AssetAllocCur
# Function to query the user's asset allocation at the current value in his selected currency from the database.


AssetAllocCur <- function(conn, last_date, main_currency) {
  query <- paste0("
    WITH NumberedQuantity AS (
    	SELECT
    		Date,
		    DisplayName,
    		TickerSymbol,
    		Type,
    		[Group],
    		QuantityCum,
    		ROW_NUMBER() OVER (
    			PARTITION BY
    			  DisplayName,
    				TickerSymbol,
    				Type,
    				[Group]
    			ORDER BY Date DESC
    		) AS RowNumber,
    		SourceCurrency
    	FROM vAssetsCumQuant
    	WHERE Date <= '", last_date, "'
    ),
    CurrentPortfolio AS (
    	SELECT
    	  nq.DisplayName,
    		nq.TickerSymbol,
    		nq.Type,
    		nq.[Group],
    		nq.QuantityCum,
    		nq.SourceCurrency
    	FROM NumberedQuantity nq
    	WHERE RowNumber = 1
    ),
    NumberedPrices AS (
    	SELECT
    		Date,
    		TickerSymbol,
    		Adjusted,
    		ROW_NUMBER() OVER (
    			PARTITION BY
    				TickerSymbol
    			ORDER BY Date DESC
    		) AS RowNumber
    	FROM price_data
    	WHERE Date <= '", last_date, "'
    ),
    CurrentPrices AS (
    	SELECT
    		np.Date,
    		np.TickerSymbol,
    		np.Adjusted
    	FROM NumberedPrices np
    	WHERE np.RowNumber = 1
    ),
    PosSizeUSD AS (
    	SELECT 
    		cprice.Date,
		    cportf.DisplayName,
    		cprice.TickerSymbol,
    		cportf.Type,
    		cportf.[Group],
    		cportf.QuantityCum * cprice.Adjusted * CASE
    			WHEN cportf.SourceCurrency = 'USD' THEN 1
    			ELSE xr.XRate
    		END AS PositionSizeUSD
    	FROM CurrentPrices cprice
    	LEFT JOIN CurrentPortfolio cportf
    		ON cprice.TickerSymbol = cportf.TickerSymbol
    	LEFT JOIN vAssetsXRates xr
    		ON cprice.Date = xr.Date
    		AND cportf.SourceCurrency = xr.Currency
	    WHERE cportf.QuantityCum != 0
    )
    SELECT
	    ps.DisplayName,
    	ps.TickerSymbol,
    	ps.Type,
    	ps.[Group],
    	ps.PositionSizeUSD / xr.XRate AS PositionSize
    FROM PosSizeUSD ps
    LEFT JOIN vAssetsXRates xr
    	ON ps.Date = xr.Date
    WHERE xr.Currency = '", main_currency, "'
  ")
  dbGetQuery(conn = conn, statement = query)
}

