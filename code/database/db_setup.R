#### Database setup
# Creating database and tables if not already existent.


### Database ----
dbConn <- dbConnect(SQLite(), "dbFinances.sqlite3")


### Income ----
dbSendQuery(
  conn      = dbConn, 
  statement = "
  CREATE TABLE IF NOT EXISTS income
  (
    Date TEXT NOT NULL,
    Amount REAL NOT NULL,
    Product TEXT,
    Source TEXT,
    Category TEXT,
    Currency TEXT NOT NULL
  );
  "
)


### Expenses ----
dbSendQuery(
  conn      = dbConn, 
  statement = "
  CREATE TABLE IF NOT EXISTS expenses
  (
    Date TEXT NOT NULL,
    Amount REAL NOT NULL,
    Product TEXT,
    Source TEXT,
    Category TEXT,
    Currency TEXT NOT NULL
  );
  "
)


### Assets ----
dbSendQuery(
  conn      = dbConn,
  statement = "
  CREATE TABLE IF NOT EXISTS assets
  (
    Date TEXT NOT NULL,
    DisplayName TEXT NOT NULL,
    Quantity REAL NOT NULL,
    PriceTotal REAL NOT NULL,
    TickerSymbol TEXT NOT NULL,
    Type TEXT NOT NULL,
    [Group] TEXT NOT NULL,
    TransactionType TEXT NOT NULL,
    TransactionCurrency TEXT NOT NULL,
    SourceCurrency TEXT NOT NULL
  );
  "
)


### Price data ----
dbSendQuery(
  conn      = dbConn, 
  statement = "
  CREATE TABLE IF NOT EXISTS price_data
  (
    Date TEXT NOT NULL,
    Open REAL,
    High REAL,
    Low REAL,
    Close REAL,
    Volume REAL,
    Adjusted REAL,
    TickerSymbol TEXT NOT NULL,
    SourceCurrency TEXT NOT NULL,
    PRIMARY KEY (Date, TickerSymbol)
  );
  "
)
# All xrates are based on USD. Hence, an entry where Currency = 'EUR' presents the xrate EUR/USD.
dbSendQuery(
  conn      = dbConn, 
  statement = "
  CREATE TABLE IF NOT EXISTS xrates
  (
    Date TEXT NOT NULL,
    Open REAL,
    High REAL,
    Low REAL,
    Close REAL,
    Volume REAL,
    Adjusted REAL,
    Currency TEXT NOT NULL,
    PRIMARY KEY (Date, Currency)
  );
  "
)


### Currency stuff ----
dbSendQuery(
  conn      = dbConn, 
  statement = "
  CREATE TABLE IF NOT EXISTS currencies
  (
    Currency TEXT NOT NULL
  );
  "
)
dbSendQuery(
  conn      = dbConn,
  statement = "
  INSERT INTO currencies (Currency)
  SELECT 'EUR'
  WHERE NOT EXISTS (
    SELECT 1 FROM currencies
  )
  UNION ALL
  SELECT 'USD'
  WHERE NOT EXISTS (
    SELECT 1 FROM currencies
  );
  "
)


### Settings ----
dbSendQuery(
  conn      = dbConn,
  statement = "
  CREATE TABLE IF NOT EXISTS settings
  (
    DarkModeOn integer not null,
    ColorProfit not null,
    ColorLoss not null,
    DateFormat text not null,
    DateFrom text not null,
    MainCurrency text not null
  );
  "
)
dbSendQuery(
  conn      = dbConn,
  statement = paste0("
  INSERT INTO settings
  SELECT 0, '#90ed7d', '#f45b5b', 'yyyy-mm-dd', '", format(Sys.Date(), "%Y"), "-01-01', 'EUR'
  WHERE NOT EXISTS (
    SELECT 1 FROM settings
  );
  ")
)


### Views ----
# Distinct assets
dbSendQuery(
  conn      = dbConn,
  statement = "
    CREATE VIEW IF NOT EXISTS vDistAssets AS
    SELECT DISTINCT
      DisplayName,
      TickerSymbol,
      Type,
      [Group],
      TransactionCurrency,
      SourceCurrency,
      SUM(
        CASE
          WHEN TransactionType = 'Buy' THEN Quantity
          ELSE -Quantity
        END
      ) AS TotalQuantity,
      (
        DisplayName || '_' || 
        TickerSymbol || '_' || 
        Type || '_' || 
        [Group] || '_' || 
        TransactionCurrency
      )AS AssetID
    FROM Assets
    GROUP BY AssetID;
  "
)

# Assets in USD
dbSendQuery(
  conn      = dbConn,
  statement = "
    CREATE VIEW IF NOT EXISTS vAssetsUSD AS
    WITH AssetsSigned AS (
    	SELECT
    		Date,
    		DisplayName,
    		CASE
    			WHEN TransactionType = 'Buy' THEN Quantity
    			ELSE -Quantity
    		END AS Quantity,
    		Case
    			WHEN TransactionType = 'Buy' THEN PriceTotal
    			ELSE -PriceTotal
    		END AS PriceTotal,
    		TickerSymbol,
    		Type,
    		[Group],
    		TransactionCurrency,
    		SourceCurrency
    	FROM assets
    )
    SELECT 
    	a.Date,
    	a.DisplayName,
    	a.Quantity,
    	a.TickerSymbol,
    	a.Type,
    	a.[Group],
    	CASE
    		WHEN a.TransactionCurrency = 'USD' THEN a.PriceTotal
    		ELSE a.PriceTotal * (
    			SELECT xr.Adjusted
    			FROM xrates xr
    			WHERE xr.Date <= a.Date
    				AND xr.Currency = a.TransactionCurrency
    			ORDER BY xr.Date DESC
    			LIMIT 1
    		)
    	END AS PriceTotalUSD,
      (
        a.DisplayName || '_' || 
    	  a.TickerSymbol || '_' || 
    	  a.Type || '_' || 
    	  a.[Group] || '_' || 
    	  a.TransactionCurrency
    	) AS AssetID
    FROM AssetsSigned a;
  "
)

# Prices in USD
dbSendQuery(
  conn      = dbConn,
  statement = "
    CREATE VIEW IF NOT EXISTS vPricesUSD AS
    SELECT 
    	pd.Date,
    	pd.TickerSymbol,
    	CASE
    		WHEN pd.SourceCurrency = 'USD' THEN pd.Adjusted
    		ELSE pd.Adjusted * (
    		  SELECT xr.Adjusted
    			FROM xrates xr
    		  WHERE xr.Date <= pd.Date
    		    AND xr.Currency = pd.SourceCurrency
    			ORDER BY xr.Date DESC
    			LIMIT 1
    		)
    	END AS PriceUSD
    FROM price_data pd;
  "
)

