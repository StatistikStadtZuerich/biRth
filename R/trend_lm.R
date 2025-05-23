#' trend prediction with linear model
#'
#' @param input_lm # tibble with variables year, y, spatial_unit, nat
#' @param year_begin # begin of prediction
#' @param year_end # end of prediction
#' @param trend_past # amount of past years that are used to fit the model
#' @param trend_prop # y value of the end point: proportion of trend vs. past
#'
#' @return #tibble with prediction data
#' @export
#'
#' @examples
trend_lm <- function(input_lm, year_begin, year_end, trend_past, trend_prop) {
  
  # years: numeric  
    year_begin <- as.numeric(year_begin)  
    year_end <- as.numeric(year_end) 
    trend_past <- as.numeric(trend_past)
    trend_prop <- as.numeric(trend_prop)    
    
  # last year of the past
    past_last <- input_lm |> 
      dplyr::filter(year == max(year)) |> 
      dplyr::rename(y_past_last = y) |> 
      dplyr::select(spatial_unit, nat, y_past_last)      
    
  # input data: select years before model fit
  in_dat <- input_lm |>
    dplyr::filter(year >= max(year) - trend_past + 1)

  # fit the model
  lm_fit <- lm(y ~ year * spatial_unit * nat, data = in_dat)

  # prediction (on purpose until the end of the temporal forecast)
  new_data <- tidyr::expand_grid(
    year = year_begin:year_end,
    spatial_unit = unique(in_dat$spatial_unit),
    nat = unique(in_dat$nat)
  )
  lm_pred <- new_data |>
    dplyr::mutate(
      y_pred = pmax(0, predict(lm_fit, newdata = new_data)),
      category = "lm"
    ) |> 
  dplyr::left_join(past_last, by = c("spatial_unit", "nat")) |> 
  dplyr::mutate(
    y = pmax(0, y_past_last + trend_prop * (y_pred - y_past_last))) |> 
  dplyr::select(spatial_unit, nat, year, y, category)

  # output
  return(lm_pred)
}
