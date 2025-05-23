#' temporal model: start and end point 
#'
#' @param input_past #tibble with variables year, x, spatial_unit, nat
#' @param input_trend #tibble with variables year, x, spatial_unit, nat, category
#' @param year_begin # begin of prediction (temporal model)
#' @param year_end # end of prediction (temporal model)
#' @param trend_prop # y value of the end point: proportion of trend vs. past
#' @param z0_prop # proportion of the calculated slope of the start point (z0)
#' @param z1_prop # proportion of the calculated slope of the end point (z1)
#'
#' @return
#' @export
#'
#' @examples
temporal_points <- function(input_past, input_trend, year_begin, year_end, trend_prop, z0_prop, z1_prop){
  
# numeric  
  year_begin <- as.numeric(year_begin)  
  year_end <- as.numeric(year_end) 
  trend_prop <- as.numeric(trend_prop)  
  z0_prop <- as.numeric(z0_prop)  
  z1_prop <- as.numeric(z1_prop)  
    

# prepare past data 
past_prep <- input_past |> 
  dplyr::mutate(category = "past")  
  
past_last <- input_past |> 
  dplyr::filter(year == max(year)) |> 
  dplyr::rename(y_past_last = y) |> 
  dplyr::select(spatial_unit, nat, y_past_last)

# prepare point data
points_prep <- past_prep |> 
  dplyr::bind_rows(input_trend) |> 
  dplyr::arrange(spatial_unit, nat, year) |>   
  dplyr::left_join(past_last, by = c("spatial_unit", "nat")) |> 
  dplyr::mutate(
    y_new = pmax(0, if_else(year <= year_begin, y,
      y_past_last + trend_prop * (y - y_past_last))),
    delta_y = c(NA, diff(y_new)),
    delta_x = c(NA, diff(year)),
    z = delta_y / delta_x    
    ) |> 
  dplyr::select(spatial_unit, nat, year, y_new, z)  

# end point
point_end <- points_prep |> 
  dplyr::filter(year == year_end) |> 
  dplyr::rename(x1 = year, y1 = y_new, z1 = z)

# start and end point 
points <- points_prep |> 
  dplyr::filter(year == year_begin) |> 
  dplyr::rename(x0 = year, y0 = y_new, z0 = z) |> 
  dplyr::left_join(point_end, by = c("spatial_unit", "nat")) |> 
  dplyr::mutate(z0 = z0 * z0_prop, z1 = z1 * z1_prop)

return(points)

}


