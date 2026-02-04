#' List available curve mnemonics in an index
#'
#' @param index Output of index_laslogs()
#' @param county Optional county filter (character vector)
#' @param top_n If not NULL, return only the top N most common curves
#' @return Tibble with MNEM and n (count of wells containing the curve)
#' @export
available_curves <- function(index, county = NULL, top_n = NULL) {
  curves <- index$curves_index
  wells  <- index$wells_index

  if (!is.null(county)) {
    keep <- wells |>
      dplyr::mutate(county = toupper(trimws(.data$county))) |>
      dplyr::filter(.data$county %in% toupper(trimws(county))) |>
      dplyr::pull(.data$api)

    curves <- curves |> dplyr::filter(.data$api %in% keep)
  }

  out <- curves |>
    dplyr::mutate(MNEM = toupper(trimws(.data$MNEM))) |>
    dplyr::filter(!is.na(.data$MNEM), .data$MNEM != "") |>
    dplyr::distinct(.data$api, .data$MNEM) |>
    dplyr::count(.data$MNEM, name = "n", sort = TRUE)

  if (!is.null(top_n)) out <- out |> dplyr::slice_head(n = top_n)
  out
}
