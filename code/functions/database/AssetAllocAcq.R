#### AssetAllocAcq
# Function to query the user's asset allocation at the acquisition value in his selected currency from the database.


AssetAllocAcq <- function(conn, last_date, main_currency) {
  if (main_currency != 'USD')  {
    query <- paste0("
    WITH
    CurrentPositions AS (
      SELECT *
      FROM vAssetsUSD
      WHERE Date <= '", last_date, "'
    ),
    AggregatedPositions AS (
      SELECT
        cp.Date,
        cp.DisplayName,
        cp.TickerSymbol,
        cp.Type,
        cp.[Group],
      SUM (
        CASE
          WHEN cp.Quantity >= 0 THEN cp.Quantity
          ELSE 0
        END
      ) AS QuantPos,
      SUM (
        CASE
          WHEN cp.Quantity < 0 THEN cp.Quantity
          ELSE 0
        END
      ) AS QuantNeg,
      SUM (
        CASE
          WHEN cp.Quantity >= 0 THEN cp.PriceUSD
          ELSE 0
        END
      ) AS PriceUSDPos
      FROM CurrentPositions cp
      GROUP BY
        DisplayName,
        TickerSymbol,
        Type,
        [Group]
    ),
    TotalPositions AS (
      SELECT
        Date,
        DisplayName,
        TickerSymbol,
        Type,
        [Group],
        PriceUSDPos * ((QuantPos + QuantNeg) / QuantPos) AS PriceTotalUSD
      FROM AggregatedPositions as ap
    )
    SELECT
      tp.Date,
      tp.DisplayName,
      tp.TickerSymbol,
      tp.Type,
      tp.[Group],
      tp.PriceTotalUSD / ar.XRate AS PositionSize
    FROM TotalPositions tp
    LEFT JOIN vAssetsXRates ar
      ON tp.Date = ar.Date
      AND ar.Currency = '", main_currency, "'
    WHERE tp.PriceTotalUSD > 0;
  ")
  } else  {
    query <- paste0("
    WITH
    CurrentPositions AS (
      SELECT *
        FROM vAssetsUSD
      WHERE Date <= '", last_date, "'
    ),
    AggregatedPositions AS (
      SELECT
        cp.Date,
        cp.DisplayName,
        cp.TickerSymbol,
        cp.Type,
        cp.[Group],
      SUM (
        CASE
          WHEN cp.Quantity >= 0 THEN cp.Quantity
          ELSE 0
        END
      ) AS QuantPos,
      SUM (
        CASE
          WHEN cp.Quantity < 0 THEN cp.Quantity
          ELSE 0
        END
      ) AS QuantNeg,
      SUM (
        CASE
          WHEN cp.Quantity >= 0 THEN cp.PriceUSD
          ELSE 0
        END
      ) AS PriceUSDPos
      FROM CurrentPositions cp
      GROUP BY
        DisplayName,
        TickerSymbol,
        Type,
        [Group]
    ),
    TotalPositions AS (
      SELECT
        Date,
        DisplayName,
        TickerSymbol,
        Type,
        [Group],
        PriceUSDPos * ((QuantPos + QuantNeg) / QuantPos) AS PriceTotalUSD
      FROM AggregatedPositions as ap
    )
    SELECT
      tp.Date,
      tp.DisplayName,
      tp.TickerSymbol,
      tp.Type,
      tp.[Group],
      tp.PriceTotalUSD AS PositionSize
    FROM TotalPositions tp
    WHERE tp.PriceTotalUSD > 0;
  ")
  }
  dbGetQuery(conn = conn, statement = query)
}

