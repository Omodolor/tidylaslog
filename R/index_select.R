#' Read LAS header only (no ~A data)
#'
#' @param file Path to a .las file
#' @return S3 object of class "laslog_header" with VERSION/WELL/CURVE/PARAMETER/OTHER plus provenance
#' @export
read_laslog_header <- function(file) {
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

  out <- list(
    VERSION = VERSION,
    WELL = WELL,
    CURVE = CURVE,
    PARAMETER = PARAMETER,
    OTHER = OTHER,
    null_value = null_val,
    source_file = file
  )
  class(out) <- "laslog_header"
  out
}
#' Build a FAIR index for a folder of LAS files
#'
#' @param dir Folder containing .las files
#' @return A list with wells_index, curves_index, files_index
#' @export
index_laslogs <- function(dir) {
  dir <- path.expand(dir)

  files <- list.files(
    dir,
    pattern = "\\.las$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(files) == 0) stop("No LAS files found in: ", dir)

  wells_list <- vector("list", length(files))
  curves_list <- vector("list", length(files))

  for (i in seq_along(files)) {
    h <- read_laslog_header(files[i])
    w <- h$WELL
    c <- h$CURVE

    api <- w |> dplyr::filter(.data$MNEM == "API") |> dplyr::pull(.data$VALUE)
    api <- if (length(api)) api[1] else NA_character_

    uwi <- w |> dplyr::filter(.data$MNEM == "UWI") |> dplyr::pull(.data$VALUE)
    uwi <- if (length(uwi)) uwi[1] else NA_character_

    county <- w |> dplyr::filter(.data$MNEM %in% c("CNTY","COUNTY")) |> dplyr::pull(.data$VALUE)
    county <- if (length(county)) county[1] else NA_character_

    state <- w |> dplyr::filter(.data$MNEM %in% c("STAT","STATE")) |> dplyr::pull(.data$VALUE)
    state <- if (length(state)) state[1] else NA_character_

    lat <- w |> dplyr::filter(.data$MNEM %in% c("LAT","LATI","LATITUDE")) |> dplyr::pull(.data$VALUE)
    lat <- if (length(lat)) suppressWarnings(as.numeric(lat[1])) else NA_real_

    lon <- w |> dplyr::filter(.data$MNEM %in% c("LONG","LON","LONGITUDE")) |> dplyr::pull(.data$VALUE)
    lon <- if (length(lon)) suppressWarnings(as.numeric(lon[1])) else NA_real_

    well_name <- w |> dplyr::filter(.data$MNEM == "WELL") |> dplyr::pull(.data$VALUE)
    well_name <- if (length(well_name)) well_name[1] else NA_character_

    company <- w |> dplyr::filter(.data$MNEM %in% c("COMP","COMPANY")) |> dplyr::pull(.data$VALUE)
    company <- if (length(company)) company[1] else NA_character_

    wells_list[[i]] <- tibble::tibble(
      api = api,
      uwi = uwi,
      county = county,
      state = state,
      latitude = lat,
      longitude = lon,
      well = well_name,
      company = company,
      null_value = h$null_value,
      source_file = basename(files[i]),
      file_path = files[i]
    )

    if (nrow(c) > 0) {
      curves_list[[i]] <- c |>
        dplyr::mutate(
          api = api,
          county = county,
          source_file = basename(files[i]),
          file_path = files[i],
          .before = 1
        )
    } else {
      curves_list[[i]] <- tibble::tibble(
        api = api, county = county, source_file = basename(files[i]),
        file_path = files[i], MNEM = character(), UNIT = character(),
        API_CODE = character(), DESC = character()
      )
    }
  }

  wells_index <- dplyr::bind_rows(wells_list) |> dplyr::distinct(.data$api, .keep_all = TRUE)
  curves_index <- dplyr::bind_rows(curves_list)

  files_index <- wells_index |>
    dplyr::select(.data$api, .data$file_path, .data$source_file)

  list(
    wells_index = wells_index,
    curves_index = curves_index,
    files_index = files_index
  )
}

#' Select wells from an index by metadata and curve availability
#'
#' @param index Output of index_laslogs()
#' @param county Character vector of counties to keep (optional)
#' @param curves_any Keep wells that have at least one of these curves (optional)
#' @param curves_all Keep wells that have all of these curves (optional)
#' @return Character vector of API values
#' @export
select_laslogs <- function(index, county = NULL, curves_any = NULL, curves_all = NULL) {
  wells <- index$wells_index
  curves <- index$curves_index

  if (!is.null(county)) {
    county_keep <- toupper(trimws(county))

    wells <- wells |>
      dplyr::mutate(county = trimws(.data$county)) |>
      dplyr::filter(!is.na(.data$county), .data$county != "") |>
      dplyr::filter(toupper(.data$county) %in% county_keep)
  }


  apis <- wells$api

  if (!is.null(curves_any)) {
    have_any <- curves |>
      dplyr::filter(.data$api %in% apis, toupper(.data$MNEM) %in% toupper(curves_any)) |>
      dplyr::distinct(.data$api) |>
      dplyr::pull(.data$api)
    apis <- intersect(apis, have_any)
  }

  if (!is.null(curves_all)) {
    want <- toupper(curves_all)
    have_all <- curves |>
      dplyr::filter(.data$api %in% apis) |>
      dplyr::mutate(MNEM = toupper(.data$MNEM)) |>
      dplyr::group_by(.data$api) |>
      dplyr::summarise(has = all(want %in% .data$MNEM), .groups = "drop") |>
      dplyr::filter(.data$has) |>
      dplyr::pull(.data$api)
    apis <- intersect(apis, have_all)
  }

  apis
}
