#' Read a LAS well log file (Log ASCII Standard) into a structured object
#'
#' @param file Path to a .las file
#' @param output Output format for LOG: "long" (tidy) or "wide"
#' @return An S3 object of class "laslog" with VERSION/WELL/CURVE/PARAMETER/OTHER/LOG
#' @export
read_laslog <- function(file, output = c("long","wide")) {
  output <- match.arg(output)

  lines <- readLines(file, warn = FALSE)
  secs <- split_las_sections(lines)

  VERSION   <- if (!is.null(secs[["VERSION"]]) || !is.null(secs[["V"]])) parse_header_block(secs[["VERSION"]] %||% secs[["V"]]) else parse_header_block(character())
  WELL      <- if (!is.null(secs[["WELL"]])    || !is.null(secs[["W"]])) parse_header_block(secs[["WELL"]] %||% secs[["W"]]) else parse_header_block(character())
  CURVE     <- if (!is.null(secs[["CURVE"]])   || !is.null(secs[["C"]])) parse_curve_block(secs[["CURVE"]] %||% secs[["C"]]) else parse_curve_block(character())
  PARAMETER <- if (!is.null(secs[["PARAMETER"]]) || !is.null(secs[["P"]])) parse_header_block(secs[["PARAMETER"]] %||% secs[["P"]]) else parse_header_block(character())
  OTHER     <- secs[["OTHER"]] %||% secs[["O"]] %||% character()

  null_val <- WELL |>
    dplyr::filter(.data$MNEM == "NULL") |>
    dplyr::pull(.data$VALUE)
  null_val <- if (length(null_val)) suppressWarnings(as.numeric(null_val[1])) else NA_real_

  LOG <- if (!is.null(secs[["A"]])) parse_ascii_block(secs[["A"]], null_value = null_val, output = output) else tibble::tibble()

  api <- WELL |> dplyr::filter(.data$MNEM == "API") |> dplyr::pull(.data$VALUE) |> (\(x) if (length(x)) x[1] else NA_character_)()
  cnty <- WELL |> dplyr::filter(.data$MNEM %in% c("CNTY","COUNTY")) |> dplyr::pull(.data$VALUE) |> (\(x) if (length(x)) x[1] else NA_character_)()
  lat  <- WELL |> dplyr::filter(.data$MNEM %in% c("LAT","LATI","LATITUDE")) |> dplyr::pull(.data$VALUE) |> (\(x) if (length(x)) suppressWarnings(as.numeric(x[1])) else NA_real_)()
  lon  <- WELL |> dplyr::filter(.data$MNEM %in% c("LONG","LON","LONGITUDE")) |> dplyr::pull(.data$VALUE) |> (\(x) if (length(x)) suppressWarnings(as.numeric(x[1])) else NA_real_)()

  if (nrow(LOG) > 0) {
    LOG <- LOG |> dplyr::mutate(
      api = api,
      county = cnty,
      latitude = lat,
      longitude = lon,
      source_file = basename(file),
      .before = 1
    )
  }

  out <- list(
    VERSION = VERSION,
    WELL = WELL,
    CURVE = CURVE,
    PARAMETER = PARAMETER,
    OTHER = OTHER,
    LOG = LOG,
    null_value = null_val,
    source_file = file
  )
  class(out) <- "laslog"
  out
}

# helper for NULL-coalescing
`%||%` <- function(x, y) if (!is.null(x)) x else y
