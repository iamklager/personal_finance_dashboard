#### hcAssetAllocAcq
# Plots the user's asset allocation at acquisition value for his selected currency.


hcAssetAllocAcq <- function(df, current_assets, to, main_currency, darkmode_on) {
  if (is.null(df) | (length(current_assets) == 0)) {
    return(
      shiny::validate(
        need((!is.null(df) & (length(current_assets) != 0)), "No data available.")
      )
    )
  }
  
  df <- df[(df$Date <= to) & (df$AssetID %in% current_assets), ]
  df <- split(df, df$AssetID)
  df <- dplyr::bind_rows(lapply(df, function(x) {
    x <- x[x$Date == max(x$Date), ]
  }))
  
  res <- highchart2() |> 
    hc_plotOptions(
      column = list(
        borderWidth = 0, 
        stacking = "normal",
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = paste0(" ", main_currency)
        )
      )
    ) |> 
    hc_xAxis(type = "category") |> 
    hc_yAxis(title = list(text = "Amount")) |> 
    hc_add_series(data = df, hcaes(x = Type, y = AcqVal, group = DisplayName), type = "column")
  
  if (darkmode_on) {
    hc_add_theme(res, hc_theme_dark())
  } else {
    hc_add_theme(res, hc_theme_light())
  }
}

