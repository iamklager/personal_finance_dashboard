#### FirstDate
# Returns the first found in all the data.


FirstDate <- function(conn) {
  res <- dbGetQuery(
    conn      = dbConn, 
    statement = "
    select min(Date)
    from (
      select Date from income
      union all
      select Date from expenses
      union all
      select Date from assets
    );
    "
  )[[1]]
  if (is.na(res)) {
    res <- format(Sys.Date(), "%Y-01-01")
  }
  
  res
}


