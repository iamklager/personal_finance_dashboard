#### hcPLSources
# Function to plot the profit/loss by source.


hcPLSources <- function(income, expenses, invested_curves, from, to, main_currency, darkmode_on) {
  if (((nrow(income) == 0) & (nrow(expenses) == 0) & is.null(invested_curves)) | (from >= to)) {
    return(
      shiny::validate(
        need(
          ((nrow(income) != 0) | (nrow(expenses) != 0) | (!is.null(invested_curves))) & (from < to), 
          "No data available."
        )
      )
    )
  }
  
  if (!is.null(invested_curves)) {
    invested_curves <- invested_curves[(invested_curves$Date >= from) & (invested_curves$Date <= to), ]
    invested_curves <- split(invested_curves, invested_curves$AssetID)
    invested_curves <- sum(unlist(lapply(invested_curves, function(x) {
      x <- x[x$Date %in% c(min(x$Date), max(x$Date)), ]
      x$Value[2] - ((x$Value[1] / x$Quantity[1]) * x$Quantity[2])
    })))
  } else {
    invested_curves <- 0
  }
  
  
  df <- data.frame(
    Source = c("Income", "Expenses", "Assets"),
    Amount = c(
      sum(income$Amount),
      - sum(expenses$Amount),
      invested_curves
    )
  )
  
  res <- highchart2() |> 
    hc_plotOptions(
      column = list(
        borderWidth = 0,
        grouping = FALSE,
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = paste0(" ", main_currency)
        )
      )
    ) |> 
    hc_xAxis(type = "category") |> 
    hc_yAxis(title = list(text = "Amount")) |> 
    hc_add_series(data = df, hcaes(x = Source, y = Amount, group = Source), type = "column")
  
  if (darkmode_on) {
    hc_add_theme(res, hc_theme_dark())
  } else {
    hc_add_theme(res, hc_theme_light())
  }
}

