#### CurrentAssets
# Function to query a character vector of all asset id's where the current quantity is != 0.


CurrentAssets <- function(conn, to) {
  unlist(dbGetQuery(
    conn = dbConn,
    statement = "
      WITH CurrentQuants AS (
        SELECT
        	SUM (
        		CASE
        			WHEN TransactionType = 'Buy' THEN Quantity
        			ELSE - Quantity
        		END
        	) AS CurQuant,
        	DisplayName || '_' ||
        	TickerSymbol || '_' ||
        	Type || '_' ||
        	[Group] || '_' ||
        	TransactionCurrency AS AssetID
        FROM assets
        WHERE Date <= ?
        GROUP BY
        	AssetID
      )
      SELECT AssetID
      FROM CurrentQuants
      WHERE CurQuant != 0
    ",
    params = as.character(to) # I hate this about RSQLite
  ))
}