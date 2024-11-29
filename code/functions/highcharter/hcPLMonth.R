#### hcPLMonth
# Function to plot profit/loss over time.

hcPLMonth <- function(income, expenses, invested_curves, from, to, main_currency, darkmode_on, col_pos, col_neg) {
  
  # Data check
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
  
  # All dates
  all_months <- sort(unique(c(income$Date, expenses$Date, invested_curves$Date)))
  all_months <- all_months[(all_months >= from) & (all_months <= to)]
  all_months <- unique(substr(all_months, 1, 7))
  
  # Income
  if (nrow(income) != 0) {
    income$Month <- substr(income$Date, 1, 7)
    income <- aggregate.data.frame(income$Amount, list(income$Month), sum)
    colnames(income) <- c("Month", "Amount")
  } else {
    income <- data.frame(
      Month = all_months,
      Amount = 0
    )
  }
  
  # Expenses
  if (nrow(expenses) != 0) {
    expenses$Month <- substr(expenses$Date, 1, 7)
    expenses <- aggregate.data.frame(-expenses$Amount, list(expenses$Month), sum)
    colnames(expenses) <- c("Month", "Amount")
  } else {
    expenses <- data.frame(
      Month = all_months,
      Amount = 0
    )
  }
  
  # Assets
  if (!is.null(invested_curves)) {
    invested_curves <- invested_curves[(invested_curves$Date >= from) & (invested_curves$Date <= to), ]
    invested_curves$Month <- substr(invested_curves$Date, 1, 7)
    invested_curves <- split(invested_curves, invested_curves$Month)
    invested_curves <- dplyr::bind_rows(lapply(invested_curves, function(curve) {
      month <- curve$Month[1]
      curve <- split(curve, curve$AssetID)
      amount <- sum(unlist(lapply(curve, function(x) {
        x <- x[x$Date %in% c(min(x$Date), max(x$Date)), ]
        x$Value[2] - ((x$Value[1] / x$Quantity[1]) * x$Quantity[2])
      })))
      data.frame(
        Month = month,
        Amount = amount
      )
    }))
  } else {
    invested_curves <- data.frame(
      Month = all_months,
      Amount = 0
    )
  }
  
  # Merged data frame
  df <- data.frame(Month = all_months)
  df <- merge(df, income, by = "Month", all = TRUE, incomparables = 0)
  colnames(df) <- c("Month", "Income")
  df <- merge(df, expenses, by = "Month", all = TRUE, incomparables = 0)
  colnames(df) <- c("Month", "Income", "Expenses")
  df <- merge(df, invested_curves, by = "Month", all = TRUE, incomparables = 0)
  colnames(df) <- c("Month", "Income", "Expenses", "Assets")
  df <- df[order(df$Month), ]
  df[is.na(df)] <- 0
  df$Amount <- df$Income + df$Expenses + df$Assets
  df$Profit <- ifelse(df$Amount >= 0, df$Amount, 0)
  df$Loss   <- ifelse(df$Amount <  0, df$Amount, 0)
  df$PLCum <- cumsum(df$Amount)
  df <- df[, c("Month", "Profit", "Loss", "PLCum")]
  
  # Chart
  res <- highchart2() |> 
    hc_plotOptions(
      column = list(
        borderWidth = 0, 
        grouping = FALSE, 
        showInLegend = FALSE,
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = paste0(" ", main_currency)
        )
      ), 
      line = list(
        lineWidth = 1, 
        marker = list(enabledThreshold = 10), 
        showInLegend = TRUE,
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = paste0(" ", main_currency)
        )
      ),
      dataSorting = list(enabled = TRUE)
    ) |> 
    hc_xAxis(title = list(text = "Month"), type = "category") |> 
    hc_yAxis(title = list(text = "Amount")) |>
    hc_add_series(
      data = df, hcaes(x = Month, y = Profit), name = "Profit", 
      type = "column", color = col_pos
    ) |> 
    hc_add_series(
      data = df, hcaes(x = Month, y = Loss), name = "Loss", 
      type = "column", color = col_neg
    ) |> 
    hc_add_series(
      data = df, hcaes(x = Month, y = PLCum), name = "Cumulative", 
      type = "line", color = ifelse(darkmode_on, "#C0C0C0", "#000000")
    )
  
  if (darkmode_on) {
    hc_add_theme(res, hc_theme_dark())
  } else {
    hc_add_theme(res, hc_theme_light())
  }
}

