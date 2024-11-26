#### QueryTableSimple
# Function to query the entire content of a table between two dates.


QueryTableSimple <- function(conn, table, date_from, date_to) {
  dbGetQuery(
    conn = conn, 
    statement = paste0(
      "select * from ", table, "\n
      where Date between '", date_from, "' and '", date_to, "'
      order by Date asc;"
    )
  )
}

