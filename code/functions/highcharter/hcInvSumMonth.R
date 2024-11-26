#### hcInvSumMonth
# Function to plot the invested sum per month.


hcInvSumMonth <- function(inv_sums, income, main_currency, darkmode_on) {
  # Data check
  if (((nrow(inv_sums) == 0) & nrow(income) == 0)) {
    return(
      shiny::validate(
        need(((nrow(df) != 0) | (nrow(income) != 0)), "No data available.")
      )
    )
  }
  
  # All months
  all_months <- sort(union(substr(income$Date, 1, 7), inv_sums$Month))
  
  # Income
  if (nrow(income) != 0) {
    income$Month <- substr(income$Date, 1, 7)
    income <- aggregate.data.frame(income$Amount, list(income$Month), sum)
    colnames(income) = c("Month", "Income")
  } else {
    income <- data.frame(Month = all_months, Income = 0)
  }
  
  # Merged data
  df <- data.frame(Month = all_months)
  income <- merge(df, income, by = "Month", all = TRUE)
  colnames(income)[2] <- "Amount"
  income$Group = "Income"
  inv_sums <- merge(df, inv_sums, by = "Month", all = TRUE)
  colnames(inv_sums)[2] <- "Amount"
  inv_sums$Group = "Investments"
  df <- rbind(income, inv_sums)
  df[is.na(df)] <- 0
  
  # Plot
  res <- highchart2() |>
    hc_plotOptions(
      column = list(
        borderWidth = 0,
        grouping = TRUE,
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = paste0(" ", main_currency)
        )
      )
    ) |> 
    hc_xAxis(type = "category", labels = list(text = "Month")) |> 
    hc_yAxis(labels = list(text = "Amount"), title = list(text = "Amount")) |> 
    hc_add_series(data = df, hcaes(x = Month, y = Amount, group = Group), type = "column")
  
  if (darkmode_on) {
    hc_add_theme(res, hc_theme_dark())
  } else {
    hc_add_theme(res, hc_theme_light())
  }
}

