#### QueryTableMainCur
# Function to query the entire content of a table between two dates in the user's main currency.

QueryTableMainCur <- function(conn, table, from, to, main_currency) {
  # Note to future me: Just use an if condition ffs!
  dbGetQuery(
    conn = conn,
    statement = paste0("
      WITH Temp AS (
      	SELECT
      		t.Date,
      		t.Amount,
      		t.Product,
      		t.Source,
      		t.Category,
      		(
      			SELECT xr.Adjusted
      			FROM xrates xr
      			WHERE t.Date <= xr.Date
      				AND xr.Currency = t.Currency
      			ORDER BY xr.Date DESC
      			LIMIT 1
      		) AS XRate
      	FROM ", table, " t
      	WHERE Date between '", from, "' AND '", to, "'
      ),
      TableUSD AS (
      	SELECT
      		Date,
      		Amount * CASE
      			WHEN XRate IS NULL THEN 1
      			ELSE XRate
      		END AS Amount,
      		Product,
      		Source,
      		Category
      	FROM Temp
      ),
      TableMainCur AS (
        SELECT
        	t.Date,
        	t.Amount,
        	t.Product,
        	t.Source,
        	t.Category,
        	t.Amount,
        	(
        		SELECT xr.Adjusted
        		FROM xrates xr
        		WHERE t.Date <= xr.Date
        			AND xr.Currency = '", main_currency, "'
        		ORDER BY xr.Date DESC
        		LIMIT 1
        	) AS XRate
        FROM TableUSD t
      )
      SELECT
      		Date,
      		Amount / CASE
      			WHEN XRate IS NULL THEN 1
      			ELSE XRate
      		END AS Amount,
      		Product,
      		Source,
      		Category,
        	(SELECT '", main_currency, "') AS Currency
      	FROM TableMainCur
    ")
  )
}

