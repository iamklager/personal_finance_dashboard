#### hcIncExpBySource
# Plots income or expenses by source.


hcIncExpBySource <- function(df, main_currency, darkmode_on) {
  if (nrow(df) == 0) {
    return(
      shiny::validate(
        need((nrow(df) != 0), "No data available.")
      )
    )
  }
  
  df <- aggregate.data.frame(df$Amount, list(df$Source), sum)
  colnames(df) <- c("Source", "Amount")
  
  res <- highchart2() |> 
    hc_plotOptions(
      column = list(
        borderWidth = 0,
        grouping = FALSE,
        stacking = "normal",
        tooltip = list(
          valueDecimals = 2, 
          valueSuffix = paste0(" ", main_currency)
        )
      )
    ) |>
    hc_xAxis(type = "category") |> 
    hc_yAxis(title = list(text = "Amount")) |> 
    hc_add_series(data = df, hcaes(x = Source, y = Amount, group = Source), type = "column") |> 
    hc_legend(enabled = F)
  
  if (darkmode_on) {
    hc_add_theme(res, hc_theme_dark())
  } else {
    hc_add_theme(res, hc_theme_light())
  }
}


