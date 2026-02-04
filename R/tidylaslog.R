#' Universal entry point: read or export LAS logs from a file or folder
#'
#' Works for a single LAS file OR a folder of LAS files. If `out_dir` is provided,
#' it exports CSV/Parquet and (optionally) writes metadata + a manifest.
#'
#' @param x Path to a .las file OR a folder containing .las files
#' @param county Optional county filter (folder mode)
#' @param curves_any Keep wells that have at least one of these curves (folder mode)
#' @param curves_all Keep wells that have all of these curves (folder mode)
#' @param curves Curves to actually export/keep (defaults to curves_all, else curves_any, else NULL=all)
#' @param output "wide" (ML-ready) or "long" (tidy)
#' @param out_dir If NULL: returns data only. If provided: writes outputs to this directory.
#'   If relative (e.g. "exports"), it is created inside `x` when `x` is a folder.
#' @param prefix Optional file prefix for exported files
#' @param formats Output formats: "csv", "parquet", or c("csv","parquet")
#' @param write_index Write index tables in addition to data export? (folder mode)
#' @param write_meta Write metadata tables for single-file export?
#' @param meta_sections Which metadata sections to export (single-file export)
#' @param manifest Write a manifest file describing the run?
#' @return If `out_dir` is NULL:
#'   - file mode: returns the laslog object from read_laslog()
#'   - folder mode: returns a list(index, apis, data)
#' If `out_dir` is provided:
#'   - file mode: returns list(data, object, paths, meta_paths, manifest)
#'   - folder mode: returns the full export result list (like batch_export_laslogs)
#' @export
tidylaslog <- function(x,
                       county = NULL,
                       curves_any = NULL,
                       curves_all = NULL,
                       curves = NULL,
                       output = c("wide","long"),
                       out_dir = NULL,
                       prefix = NULL,
                       formats = c("csv","parquet"),
                       write_index = TRUE,
                       write_meta = TRUE,
                       meta_sections = c("VERSION","WELL","CURVE","PARAMETER","OTHER"),
                       manifest = TRUE) {

  output <- match.arg(output)
  x <- path.expand(x)

  formats <- tolower(formats)
  csv <- "csv" %in% formats
  parquet <- "parquet" %in% formats

  is_file <- file.exists(x) && !dir.exists(x)
  is_dir  <- dir.exists(x)

  if (!is_file && !is_dir) {
    stop("`x` must be an existing .las file or a directory containing .las files: ", x)
  }

  # ---- Single file mode ----
  if (is_file) {
    if (!grepl("\\.las$", x, ignore.case = TRUE)) {
      stop("File does not look like a .las: ", x)
    }

    obj <- read_laslog(x, output = output)

    # Keep only selected curves if requested
    if (!is.null(curves)) {
      want <- toupper(curves)
      if (output == "long") {
        obj$LOG <- obj$LOG |> dplyr::filter(toupper(.data$mnemonic) %in% want)
      } else {
        meta <- c("api", "county", "latitude", "longitude", "source_file", "depth")
        keep <- intersect(names(obj$LOG), want)
        obj$LOG <- obj$LOG |> dplyr::select(dplyr::any_of(meta), dplyr::any_of(keep))
      }
    }

    # Export if requested
    if (!is.null(out_dir)) {

      # In file mode we just expand as given (relative = relative to getwd())
      out_dir <- path.expand(out_dir)

      # 1) export log table
      paths <- write_laslogs(
        obj$LOG,
        out_dir = out_dir,
        prefix  = prefix %||% "laslog",
        csv     = csv,
        parquet = parquet
      )

      # 2) export metadata tables (optional)
      meta_paths <- NULL
      if (isTRUE(write_meta)) {
        ms <- toupper(meta_sections)
        meta_paths <- list()

        if ("VERSION" %in% ms && !is.null(obj$VERSION) && nrow(obj$VERSION) > 0) {
          meta_paths$VERSION <- write_laslogs(
            obj$VERSION, out_dir,
            paste0(prefix %||% "laslog", "__meta_version"),
            csv, parquet
          )
        }

        if ("WELL" %in% ms && !is.null(obj$WELL) && nrow(obj$WELL) > 0) {
          meta_paths$WELL <- write_laslogs(
            obj$WELL, out_dir,
            paste0(prefix %||% "laslog", "__meta_well"),
            csv, parquet
          )
        }

        if ("CURVE" %in% ms && !is.null(obj$CURVE) && nrow(obj$CURVE) > 0) {
          meta_paths$CURVE <- write_laslogs(
            obj$CURVE, out_dir,
            paste0(prefix %||% "laslog", "__meta_curve"),
            csv, parquet
          )
        }

        if ("PARAMETER" %in% ms && !is.null(obj$PARAMETER) && nrow(obj$PARAMETER) > 0) {
          meta_paths$PARAMETER <- write_laslogs(
            obj$PARAMETER, out_dir,
            paste0(prefix %||% "laslog", "__meta_parameter"),
            csv, parquet
          )
        }

        if ("OTHER" %in% ms) {
          other_path <- file.path(
            path.expand(out_dir),
            paste0(prefix %||% "laslog", "__meta_other.txt")
          )
          writeLines(obj$OTHER %||% character(), other_path)
          meta_paths$OTHER <- list(txt = other_path)
        }
      }

      # 3) manifest (optional)
      manifest_path <- NULL
      if (isTRUE(manifest)) {
        manifest_path <- write_manifest(
          out_dir = path.expand(out_dir),
          prefix  = prefix %||% "laslog",
          dir     = dirname(x),
          filters = list(
            file = basename(x),
            curves = curves,
            output = output,
            formats = formats,
            write_meta = write_meta,
            meta_sections = meta_sections
          ),
          n_wells = 1
        )
      }

      return(invisible(list(
        data = obj$LOG,
        object = obj,
        paths = paths,
        meta_paths = meta_paths,
        manifest = manifest_path
      )))
    }

    return(obj)
  }

  # ---- Folder mode ----

  # If user only wants data back (no exporting)
  if (is.null(out_dir)) {
    idx <- index_laslogs(x)
    apis <- select_laslogs(idx, county = county, curves_any = curves_any, curves_all = curves_all)
    if (length(apis) == 0) stop("No wells matched your filters.")
    if (is.null(curves)) curves <- curves_all %||% curves_any
    dat <- pull_laslogs(idx, apis = apis, curves = curves, output = output)
    return(list(index = idx, apis = apis, data = dat))
  }

  # If exporting, keep your existing batch exporter behavior
  batch_export_laslogs(
    dir = x,
    out_dir = out_dir,
    county = county,
    curves_any = curves_any,
    curves_all = curves_all,
    curves = curves,
    output = output,
    prefix = prefix,
    csv = csv,
    parquet = parquet,
    write_index = write_index
  )
}
