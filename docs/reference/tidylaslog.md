# Universal entry point for reading, indexing, and exporting LAS well logs

`tidylaslog()` works with either a **single LAS file** or a **directory
of LAS files**. It can return data directly to R or export
analysis-ready tables to disk.

## Usage

``` r
tidylaslog(
  x,
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
  meta_sections = c("VERSION", "WELL", "CURVE", "PARAMETER", "OTHER"),
  manifest = TRUE
)
```

## Arguments

- x:

  Path to a `.las` file OR a directory containing `.las` files.

- county:

  Optional county filter (directory mode only).

- curves_any:

  Keep wells that contain *at least one* of these curves (directory
  mode).

- curves_all:

  Keep wells that contain *all* of these curves (directory mode).

- curves:

  Curves to actually keep/export. Defaults to `curves_all`, then
  `curves_any`, otherwise all curves.

- output:

  Output format:

  "wide"

  :   One row per depth per well, curves as columns (ML- and
      spreadsheet-ready).

  "long"

  :   One row per curve measurement with columns `depth`, `mnemonic`,
      and `value` (tidy format).

- out_dir:

  If `NULL`, data are returned to R only. If provided, outputs are
  written to this directory. If relative (e.g. `"exports"`), it is
  created inside `x` when `x` is a directory.

- prefix:

  Optional filename prefix for exported files.

- formats:

  Output formats to write. One or both of `"csv"` and `"parquet"`.

- write_index:

  Write index tables (wells, curves, files) when exporting directories?

- write_meta:

  Write metadata tables (`WELL`, `CURVE`, etc.) for single-file exports?

- meta_sections:

  Which metadata sections to export (`"VERSION"`, `"WELL"`, `"CURVE"`,
  `"PARAMETER"`, `"OTHER"`).

- manifest:

  Write a JSON manifest describing the export?

## Value

If `out_dir` is `NULL`:

- Single file:

  An S3 object of class `"laslog"` containing `VERSION`, `WELL`,
  `CURVE`, `PARAMETER`, `OTHER`, and `LOG`.

- Directory:

  A list with `index`, `apis`, and combined `data`.

If `out_dir` is provided:

- Single file:

  A list containing exported data paths, metadata paths, and an optional
  manifest.

- Directory:

  The full batch export result (see
  [`batch_export_laslogs()`](https://omodolor.github.io/tidylaslog/reference/batch_export_laslogs.md)).

## Details

The function supports two equivalent representations of LAS log data:

- **Wide format**: one row per depth step per well, with each curve
  stored as a separate column.

- **Long format**: one row per measurement, with curve names stored in a
  `mnemonic` column and values in a `value` column.

Both formats contain the same information but are optimized for
different workflows (machine learning vs tidy analysis).

## Examples

``` r
# ---- Single file mode (return to R) ----
las_text <- c(
  " ~Version Information",
  " VERS. 2.0:",
  " WRAP. NO:",
  " ~Well Information",
  " STRT.M 1000:",
  " STOP.M 1002:",
  " STEP.M 1:",
  " NULL. -999.25:",
  " API . 1111111111:",
  " CNTY. TEST:",
  " ~Curve Information",
  " DEPT.M:",
  " GR.API:",
  " ~ASCII Log Data",
  " 1000 80",
  " 1001 82",
  " 1002 79"
)
f <- tempfile(fileext = ".las")
writeLines(las_text, f)
obj <- tidylaslog(f, output = "long")
head(obj$LOG)
#> # A tibble: 0 × 0

# ---- Directory mode (return to R) ----
td <- tempdir()
f1 <- file.path(td, "a.las")
f2 <- file.path(td, "b.las")
writeLines(las_text, f1)
writeLines(sub("1111111111", "2222222222", las_text), f2)
res <- tidylaslog(td, county = "TEST", curves_any = "GR", output = "wide")
names(res)
#> [1] "index" "apis"  "data" 

# ---- Export mode (CSV only, no arrow needed) ----
out_dir <- file.path(td, "exports_demo")
ex <- tidylaslog(td,
  county = "TEST",
  curves_any = "GR",
  output = "wide",
  out_dir = out_dir,
  formats = "csv",
  write_index = TRUE,
  manifest = FALSE
)
names(ex)
#> [1] "index"       "apis"        "data"        "paths"       "index_paths"
#> [6] "manifest"   
```
