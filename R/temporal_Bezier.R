#' temporal model: Bézier
#'
#' @param points_dat # tibble with point information (x0, y0, z0, x1, y1, z1) by spatial_unit, nat
#' @param year_begin # begin of prediction
#' @param year_end # end of prediction
#'
#' @return #tibble with prediction data
#' @export
#'
#' @examples
temporal_Bezier <- function(points_dat, year_begin, year_end) {
  # parameters
  
  # years: numeric  
    year_begin <- as.numeric(year_begin)  
    year_end <- as.numeric(year_end)    
  
  Bezier_para <- points_dat |>
    dplyr::mutate(
      delta_z = if_else(z0 - z1 == 0, 0.000000001, z0 - z1),
      xc = ((x0 * z0) - (x1 * z1) + y1 - y0) / delta_z,
      yc = ((y1 * z0) - (y0 * z1) + (z0 * z1 * (x0 - x1))) / delta_z
    )

  # prediction
  pred <- tidyr::expand_grid(
    year = year_begin:year_end,
    spatial_unit = unique(points_dat$spatial_unit),
    nat = unique(points_dat$nat)
  ) |>
    dplyr::left_join(Bezier_para, by = c("spatial_unit", "nat")) |>
    dplyr::mutate(
      t1 = ((x1 - xc) + (((x1 - xc)**2) + ((year - x1) * (x0 + x1 - (2 * xc))))**(0.5)) / (x0 + x1 - (2 * xc)),
      t2 = ((x1 - xc) - (((x1 - xc)**2) + ((year - x1) * (x0 + x1 - (2 * xc))))**(0.5)) / (x0 + x1 - (2 * xc)),
      yt1 = pmax(0, (t1 * ((t1 * y0) + ((1 - t1) * yc))) + ((1 - t1) * ((t1 * yc) + ((1 - t1) * y1)))),
      y = pmax(0, (t2 * ((t2 * y0) + ((1 - t2) * yc))) + ((1 - t2) * ((t2 * yc) + ((1 - t2) * y1)))),
      category = "Bézier"
    ) |>
    dplyr::select(spatial_unit, nat, year, y, category)

  # output
  return(pred)
}
