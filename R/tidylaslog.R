#' Universal entry point for reading, indexing, and exporting LAS well logs
#'
#' `tidylaslog()` works with either a **single LAS file** or a **directory of LAS files**.
#' It can return data directly to R or export analysis-ready tables to disk.
#'
#' The function supports two equivalent representations of LAS log data:
#'
#' - **Wide format**: one row per depth step per well, with each curve stored as a
#'   separate column.
#' - **Long format**: one row per measurement, with curve names stored in a
#'   `mnemonic` column and values in a `value` column.
#'
#' Both formats contain the same information but are optimized for different workflows
#' (machine learning vs tidy analysis).
#'
#' @param x Path to a `.las` file OR a directory containing `.las` files.
#'
#' @param county Optional county filter (directory mode only).
#'
#' @param curves_any Keep wells that contain *at least one* of these curves
#'   (directory mode).
#'
#' @param curves_all Keep wells that contain *all* of these curves
#'   (directory mode).
#'
#' @param curves Curves to actually keep/export. Defaults to `curves_all`,
#'   then `curves_any`, otherwise all curves.
#'
#' @param output Output format:
#' \describe{
#'   \item{"wide"}{One row per depth per well, curves as columns
#'   (ML- and spreadsheet-ready).}
#'   \item{"long"}{One row per curve measurement with columns
#'   `depth`, `mnemonic`, and `value` (tidy format).}
#' }
#'
#' @param out_dir If `NULL`, data are returned to R only.
#'   If provided, outputs are written to this directory.
#'   If relative (e.g. `"exports"`), it is created inside `x` when `x` is a directory.
#'
#' @param prefix Optional filename prefix for exported files.
#'
#' @param formats Output formats to write. One or both of `"csv"` and `"parquet"`.
#'
#' @param write_index Write index tables (wells, curves, files) when exporting
#'   directories?
#'
#' @param write_meta Write metadata tables (`WELL`, `CURVE`, etc.) for
#'   single-file exports?
#'
#' @param meta_sections Which metadata sections to export
#'   (`"VERSION"`, `"WELL"`, `"CURVE"`, `"PARAMETER"`, `"OTHER"`).
#'
#' @param manifest Write a JSON manifest describing the export?
#'
#' @return
#' If `out_dir` is `NULL`:
#' \describe{
#'   \item{Single file}{An S3 object of class `"laslog"` containing
#'   `VERSION`, `WELL`, `CURVE`, `PARAMETER`, `OTHER`, and `LOG`.}
#'   \item{Directory}{A list with `index`, `apis`, and combined `data`.}
#' }
#'
#' If `out_dir` is provided:
#' \describe{
#'   \item{Single file}{A list containing exported data paths, metadata paths,
#'   and an optional manifest.}
#'   \item{Directory}{The full batch export result (see `batch_export_laslogs()`).}
#' }
#'
#' @export
#' @examples
#' # ---- Single file mode (return to R) ----
#' las_text <- c(
#'   " ~Version Information",
#'   " VERS. 2.0:",
#'   " WRAP. NO:",
#'   " ~Well Information",
#'   " STRT.M 1000:",
#'   " STOP.M 1002:",
#'   " STEP.M 1:",
#'   " NULL. -999.25:",
#'   " API . 1111111111:",
#'   " CNTY. TEST:",
#'   " ~Curve Information",
#'   " DEPT.M:",
#'   " GR.API:",
#'   " ~ASCII Log Data",
#'   " 1000 80",
#'   " 1001 82",
#'   " 1002 79"
#' )
#' f <- tempfile(fileext = ".las")
#' writeLines(las_text, f)
#' obj <- tidylaslog(f, output = "long")
#' head(obj$LOG)
#'
#' # ---- Directory mode (return to R) ----
#' td <- tempdir()
#' f1 <- file.path(td, "a.las")
#' f2 <- file.path(td, "b.las")
#' writeLines(las_text, f1)
#' writeLines(sub("1111111111", "2222222222", las_text), f2)
#' res <- tidylaslog(td, county = "TEST", curves_any = "GR", output = "wide")
#' names(res)
#'
#' # ---- Export mode (CSV only, no arrow needed) ----
#' out_dir <- file.path(td, "exports_demo")
#' ex <- tidylaslog(td,
#'   county = "TEST",
#'   curves_any = "GR",
#'   output = "wide",
#'   out_dir = out_dir,
#'   formats = "csv",
#'   write_index = TRUE,
#'   manifest = FALSE
#' )
#' names(ex)
tidylaslog <- function(x,
                       county = NULL,
                       curves_any = NULL,
                       curves_all = NULL,
                       curves = NULL,
                       output = c("wide", "long"),
                       out_dir = NULL,
                       prefix = NULL,
                       formats = c("csv", "parquet"),
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
    stop("`x` must be an existing .las file or directory: ", x)
  }

  # ---- Single file mode ----
  if (is_file) {
    obj <- read_laslog(x, output = output)

    if (!is.null(curves)) {
      want <- toupper(curves)
      if (output == "long") {
        obj$LOG <- dplyr::filter(obj$LOG, toupper(.data$mnemonic) %in% want)
      } else {
        meta <- c("api","county","latitude","longitude","source_file","depth")
        keep <- intersect(names(obj$LOG), want)
        obj$LOG <- dplyr::select(obj$LOG, dplyr::any_of(meta), dplyr::any_of(keep))
      }
    }

    if (is.null(out_dir)) return(obj)

    out_dir <- path.expand(out_dir)

    paths <- write_laslogs(obj$LOG, out_dir, prefix %||% "laslog", csv, parquet)

    meta_paths <- NULL
    if (write_meta) {
      meta_paths <- list()
      if ("WELL" %in% meta_sections && nrow(obj$WELL) > 0)
        meta_paths$WELL <- write_laslogs(obj$WELL, out_dir,
                                         paste0(prefix %||% "laslog","__meta_well"), csv, parquet)
      if ("CURVE" %in% meta_sections && nrow(obj$CURVE) > 0)
        meta_paths$CURVE <- write_laslogs(obj$CURVE, out_dir,
                                          paste0(prefix %||% "laslog","__meta_curve"), csv, parquet)
    }

    manifest_path <- NULL
    if (manifest) {
      manifest_path <- write_manifest(out_dir, prefix %||% "laslog",
                                      dirname(x),
                                      list(curves = curves, output = output),
                                      n_wells = 1)
    }

    return(invisible(list(
      data = obj$LOG,
      object = obj,
      paths = paths,
      meta_paths = meta_paths,
      manifest = manifest_path
    )))
  }

  # ---- Directory mode ----
  if (is.null(out_dir)) {
    idx <- index_laslogs(x)
    apis <- select_laslogs(idx, county, curves_any, curves_all)
    if (is.null(curves)) curves <- curves_all %||% curves_any
    dat <- pull_laslogs(idx, apis, curves, output)
    return(list(index = idx, apis = apis, data = dat))
  }

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
