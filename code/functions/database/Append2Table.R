#### Append2Table
# Appends a dataframe to a table.


Append2Table <- function(conn, table_name, df) {
  dbWriteTable(conn = conn, table_name, value = df, append = TRUE)
}