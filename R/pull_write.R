#' Pull log data for selected wells (optionally selected curves)
#'
#' @param index Output of index_laslogs()
#' @param apis Character vector of API values to load
#' @param curves Optional curve mnemonics to keep (e.g., c("GR","RHOB","NPHI"))
#' @param output "long" (tidy) or "wide" (ML-ready)
#' @return A tibble combining all selected wells
#' @export
pull_laslogs <- function(index, apis, curves = NULL, output = c("long", "wide")) {
  output <- match.arg(output)

  files_tbl <- index$files_index |>
    dplyr::filter(.data$api %in% apis)

  if (nrow(files_tbl) == 0) {
    stop("No matching APIs found in index$files_index.")
  }

  logs <- vector("list", nrow(files_tbl))

  for (i in seq_len(nrow(files_tbl))) {
    lf <- read_laslog(files_tbl$file_path[i], output = output)
    dat <- lf$LOG

    if (!is.null(curves) && nrow(dat) > 0) {
      want <- toupper(curves)

      if (output == "long") {
        dat <- dat |> dplyr::filter(toupper(.data$mnemonic) %in% want)
      } else {
        meta <- c("api", "county", "latitude", "longitude", "source_file", "depth")
        keep <- intersect(names(dat), want)
        dat <- dat |> dplyr::select(dplyr::any_of(meta), dplyr::any_of(keep))
      }
    }

    logs[[i]] <- dat
  }

  dplyr::bind_rows(logs)
}

#' Write LAS logs to CSV and/or Parquet
#'
#' @param data Tibble returned by pull_laslogs()
#' @param out_dir Output directory
#' @param prefix File prefix (no extension)
#' @param csv Write CSV file?
#' @param parquet Write Parquet file? (requires arrow)
#' @return Invisibly returns output paths
#' @export
write_laslogs <- function(data, out_dir, prefix = "laslogs", csv = TRUE, parquet = TRUE) {
  out_dir <- path.expand(out_dir)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  csv_path <- NULL
  pq_path  <- NULL

  if (isTRUE(csv)) {
    csv_path <- file.path(out_dir, paste0(prefix, ".csv"))
    utils::write.csv(data, csv_path, row.names = FALSE)
  }

  if (isTRUE(parquet)) {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("Package 'arrow' is required for Parquet output. Install with install.packages('arrow').")
    }
    pq_path <- file.path(out_dir, paste0(prefix, ".parquet"))
    arrow::write_parquet(data, pq_path)
  }

  invisible(list(csv = csv_path, parquet = pq_path))
}

#' Index, filter, pull, and export LAS logs in one call
#'
#' @param dir Folder containing .las files
#' @param out_dir Output directory (absolute path, or relative to dir)
#' @param county Optional county filter (character vector)
#' @param curves_any Optional: keep wells with at least one of these curves
#' @param curves_all Optional: keep wells with all of these curves
#' @param curves Optional: curves to actually export (defaults to curves_all, else curves_any, else NULL=all)
#' @param output "wide" or "long"
#' @param prefix Optional file prefix. If NULL, an informative prefix is built.
#' @param csv Write CSV?
#' @param parquet Write Parquet?
#' @param write_index If TRUE, also export wells_index/curves_index/files_index tables
#' @param index_prefix Optional prefix for index files (defaults to `prefix__index`)
#' @return Invisibly returns a list with index, apis, data, output paths, and manifest
#' @export

batch_export_laslogs <- function(dir,
                                 out_dir,
                                 county = NULL,
                                 curves_any = NULL,
                                 curves_all = NULL,
                                 curves = NULL,
                                 output = c("wide", "long"),
                                 prefix = NULL,
                                 csv = TRUE,
                                 parquet = TRUE,
                                 write_index = TRUE,
                                 index_prefix = NULL) {


  output <- match.arg(output)

  dir <- path.expand(dir)

  # If out_dir is relative (e.g. "exports"), put it inside dir
  is_abs <- grepl("^/", out_dir) || grepl("^[A-Za-z]:[/\\\\]", out_dir)
  out_dir <- if (is_abs) path.expand(out_dir) else file.path(dir, out_dir)


  idx <- index_laslogs(dir)

  apis <- select_laslogs(
    idx,
    county = county,
    curves_any = curves_any,
    curves_all = curves_all
  )

  if (length(apis) == 0) {
    stop("No wells matched your filters. Try relaxing county/curves filters.")
  }

  # If user didn't specify which curves to export, infer from filters
  if (is.null(curves)) {
    curves <- curves_all %||% curves_any
  }

  dat <- pull_laslogs(idx, apis = apis, curves = curves, output = output)

  if (is.null(prefix)) {
    p1 <- if (!is.null(county)) paste0("county_", paste(tolower(county), collapse = "-")) else "all_counties"
    p2 <- if (!is.null(curves)) paste0("curves_", paste(tolower(curves), collapse = "-")) else "all_curves"
    p3 <- paste0(output)
    prefix <- paste(p1, p2, p3, sep = "__")
  }

  paths <- write_laslogs(dat, out_dir = out_dir, prefix = prefix, csv = csv, parquet = parquet)
  index_paths <- NULL

  if (isTRUE(write_index)) {
    iprefix <- index_prefix %||% paste0(prefix, "__index")

    wells_paths <- write_laslogs(
      idx$wells_index, out_dir = out_dir,
      prefix = paste0(iprefix, "__wells"),
      csv = csv, parquet = parquet
    )

    curves_paths <- write_laslogs(
      idx$curves_index, out_dir = out_dir,
      prefix = paste0(iprefix, "__curves"),
      csv = csv, parquet = parquet
    )

    files_paths <- write_laslogs(
      idx$files_index, out_dir = out_dir,
      prefix = paste0(iprefix, "__files"),
      csv = csv, parquet = parquet
    )

    index_paths <- list(wells = wells_paths, curves = curves_paths, files = files_paths)
  }

  manifest_path <- write_manifest(
    out_dir = out_dir,
    prefix = prefix,
    dir = dir,
    filters = list(
      county = county,
      curves_any = curves_any,
      curves_all = curves_all,
      curves = curves,
      output = output,
      write_index = write_index
    ),
    n_wells = length(apis)
  )


  invisible(list(
    index = idx,
    apis = apis,
    data = dat,
    paths = paths,
    index_paths = index_paths,
    manifest = manifest_path
  ))

}

#' Write a small manifest describing an export run
#'
#' @param out_dir Output directory
#' @param prefix Prefix used for outputs
#' @param dir Input LAS directory
#' @param filters List of filters (county/curves/etc.)
#' @param n_wells Number of wells selected
#' @return Path to manifest file
#' @keywords internal
#' @noRd
write_manifest <- function(out_dir, prefix, dir, filters, n_wells) {
  manifest <- list(
    package = "tidylaslog",
    version = utils::packageVersion("tidylaslog") |> as.character(),
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    input_dir = path.expand(dir),
    output_prefix = prefix,
    filters = filters,
    n_wells = n_wells
  )

  path <- file.path(out_dir, paste0(prefix, "__manifest.json"))
  json <- if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::toJSON(manifest, pretty = TRUE, auto_unbox = TRUE)
  } else {
    # fallback plain text if jsonlite isn't available
    paste(utils::capture.output(utils::str(manifest)), collapse = "\n")

  }

  writeLines(json, path)
  path
}

