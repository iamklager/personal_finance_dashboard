#### InvestedSum
# Function to query the invested sum per month.


InvestedSum <- function(conn, from, to, main_currency) {
  # I hate RSQLite for this!
  from = as.character(from)
  to = as.character(to)
  
  if (main_currency == "USD") {
    dbGetQuery(
      conn = dbConn,
      statement = "
        SELECT
        	SUBSTR(a.Date, 1, 7) AS Month,
        	SUM(
        		CASE 
        			WHEN a.PriceTotalUSD < 0 THEN 0
        			ELSE a.PriceTotalUSD
        		END
        	)AS InvestedSum
        FROM vAssetsUSD a
        WHERE a.Date between ? AND ?
        GROUP BY Month
        ORDER BY Month;
      ",
      params = c(from, to)
    )
  } else {
    dbGetQuery(
      conn = conn,
      statement = "
      SELECT
      	SUBSTR(a.Date, 1, 7) AS Month,
      	SUM(
      		CASE 
      			WHEN a.PriceTotalUSD < 0 THEN 0
      			ELSE a.PriceTotalUSD
      		END * (
      		  SELECT xr.Adjusted
      			FROM xrates xr
      		  WHERE xr.Date <= a.Date
      			AND xr.Currency = ?
      			ORDER BY xr.Date DESC
      			LIMIT 1
      		)
      	)AS InvestedSum
      FROM vAssetsUSD a
      WHERE a.Date between ? AND ?
      GROUP BY Month
      ORDER BY Month;
    ",
      params = c(main_currency, from, to)
    )
  }
  
}

