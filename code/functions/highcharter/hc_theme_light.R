#### hc_theme_light
# Custom light highcharter theme.

hc_theme_light <- function() {
  theme <- highcharter::hc_theme(chart = list(backgroundColor = "#FFFFFF"))
  # Colors from colorspace::qualitative_hcl(20, palette = "Dark 3") and shuffled
  theme$colors <- c(
    "#00A6CA", "#CE7D3B", "#CF6AD2", "#909800", "#00ABB4", "#BE8700", "#00AA5A", "#6F9F00", "#DD64BE", "#B675E0",
    "#AA9000", "#3BA52E", "#009DDA", "#5991E4", "#E16A86", "#E264A4", "#9183E6", "#00AC7C", "#00AD9A", "#DA7365"
  )
  
  return(theme)
}
