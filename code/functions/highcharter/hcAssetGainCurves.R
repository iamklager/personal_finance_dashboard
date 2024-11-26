#### hcAssetGainCurves
# Function to get the cumulated asset gain curves.


hcAssetGainCurves <- function(df, type, from, to, darkmode_on) {
  if (is.null(df) | (from >= to)) {
    return(
      shiny::validate(
        need((!is.null(df) & (from < to)), "No data available.")
      )
    )
  }
  df <- df[(df$Date >= from) & (df$Date <= to) & (df$Type == type), ]
  if (nrow(df) == 0) {
    return(
      shiny::validate(
        need(nrow(df) != 0, "No data available.")
      )
    )
  }
  
  df$RelVal <- df$Value / df$AcqVal
  df <- na.omit(df)
  df <- split(df, df$AssetID)
  df <- dplyr::bind_rows(lapply(df, function(x) {
    x$Gain = 100 * (x$RelVal - x$RelVal[x$Date == min(x$Date)])
    x
  }))
  df$Date <- as.Date(df$Date)
  
  res <- highchart2() |> 
    hc_plotOptions(
      line = list(
        borderWidth = 0, 
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = " %"
        )
      )
    ) |> 
    hc_xAxis(type = "datetime", labels = list(text = "Date")) |> 
    hc_yAxis(labels = list(text = "Price", format = "{value} %"), title = list(text = "Change")) |> 
    hc_add_series(data = df, hcaes(x = Date, y = Gain, group = DisplayName), type = "line")
  
  if (darkmode_on) {
    hc_add_theme(res, hc_theme_dark())
  } else {
    hc_add_theme(res, hc_theme_light())
  }
}



