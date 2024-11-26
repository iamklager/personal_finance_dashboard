#### QueryIncExpGrouped
# Function to query the income or expenses table grouped by source and category


QueryIncExpGrouped <- function(conn, table_name, from, to) {
  dbGetQuery(
    conn = dbConn,
    statement = paste0("
      select sum(Amount) Amount, Source, Category from ", table_name, "
      where Date between '", from, "' and '", to, "'
      group by Source, Category;
    ")
  )
}


