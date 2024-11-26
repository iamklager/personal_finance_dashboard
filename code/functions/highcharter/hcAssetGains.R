#### hcAssetGains
# Plots the user's asset gains in %.


hcAssetGains <- function(df, current_assets, type, from, to, darkmode_on) {
  # Data check
  if (is.null(df) | (from >= to)) {
    return(
      shiny::validate(
        need((!is.null(df) & (from < to)), "No data available.")
      )
    )
  }
  df <- df[(df$Date >= from) & (df$Date <= to) & (df$Type == type) & (df$AssetID %in% current_assets), ]
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
    data.frame(
      DisplayName = x$DisplayName[1],
      Group = x$Group[1],
      Gain = 100 * (x$RelVal[x$Date == max(x$Date)] - x$RelVal[x$Date == min(x$Date)])
    )
  }))
  
  res <- highchart2() |> 
    hc_plotOptions(
      column = list(
        borderWidth = 0,
        grouping = FALSE,
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = " %"
        )
      )
    ) |> 
    hc_xAxis(type = "category", title = list(text = type)) |> 
    hc_yAxis(labels = list(format = "{value} %"), title = list(text = "Change")) |> 
    hc_add_series(data = df, hcaes(x = DisplayName, y = Gain, group = Group), type = "column")
  
  if (darkmode_on) {
    hc_add_theme(res, hc_theme_dark())
  } else {
    hc_add_theme(res, hc_theme_light())
  }
}

