#### AddCurrencies
# Function to add a currencies to the database.


AddCurrencies <- function(conn, currencies) {
  lapply(currencies, function(currency) {
    dbSendQuery(
      conn = conn,
      statement = paste0("
        INSERT INTO currencies (Currency)
        SELECT '", currency, "'
        WHERE NOT EXISTS (
          SELECT 1 FROM currencies WHERE Currency = '", currency, "'
        );
      ")
    )
  })
}

