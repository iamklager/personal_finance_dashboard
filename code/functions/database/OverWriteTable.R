#### Append2Table
# Overwrites a table with the given dataframe.


OverWriteTable <- function(conn, table_name, df) {
  dbWriteTable(conn = conn, table_name, value = df, overwrite = TRUE)
}