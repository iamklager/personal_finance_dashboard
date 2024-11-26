#### QueryIncExpMonth
# Function to query the income or expenses table grouped by month.


QueryIncExpMonth <- function(conn, table_name, from, to) {
  dbGetQuery(
    conn = dbConn,
    statement = paste0("
      select strftime('%Y-%m', Date) as Month, sum(Amount) as Amount, Category
      from ", table_name, "
      where Date between '", from, "' and '", to, "'
      group by Month, Category
      order by Month asc;
    ")
  )
}
