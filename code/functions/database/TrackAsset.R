#### TrackAsset
# Function to track assets (i.e., add entries to the database after pressing the ui button).

TrackAsset <- function(
    conn, type, group, ticker_symbol, display_name, date, quantity, price_total, transaction_type, transaction_currency, 
    source_currency
) {
  dbSendQuery(
    conn = conn,
    statement = paste0("
    insert into assets
    values (
      '", date ,"',
      '", display_name ,"',
      ", quantity ,",
      ", price_total ,",
      '", ticker_symbol ,"',
      '", type ,"',
      '", group ,"',
      '", transaction_type ,"',
      '", transaction_currency ,"',
      '", source_currency ,"'
    );
    ")
  )
}

