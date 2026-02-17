# Index, filter, pull, and export LAS logs in one call

Index, filter, pull, and export LAS logs in one call

## Usage

``` r
batch_export_laslogs(
  dir,
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
  index_prefix = NULL
)
```

## Arguments

- dir:

  Folder containing .las files

- out_dir:

  Output directory (absolute path, or relative to dir)

- county:

  Optional county filter (character vector)

- curves_any:

  Optional: keep wells with at least one of these curves

- curves_all:

  Optional: keep wells with all of these curves

- curves:

  Optional: curves to actually export (defaults to curves_all, else
  curves_any, else NULL=all)

- output:

  "wide" or "long"

- prefix:

  Optional file prefix. If NULL, an informative prefix is built.

- csv:

  Write CSV?

- parquet:

  Write Parquet?

- write_index:

  If TRUE, also export wells_index/curves_index/files_index tables

- index_prefix:

  Optional prefix for index files (defaults to `prefix__index`)

## Value

Invisibly returns a list with index, apis, data, output paths, and
manifest

## Examples

``` r
td <- tempdir()
f <- file.path(td, "a.las")

las_text <- c(
  " ~Version Information",
  " VERS. 2.0:",
  " WRAP. NO:",
  " ~Well Information",
  " STRT.M 1000:",
  " STOP.M 1001:",
  " STEP.M 1:",
  " NULL. -999.25:",
  " API . 1111111111:",
  " CNTY. TEST:",
  " ~Curve Information",
  " DEPT.M:",
  " GR.API:",
  " ~ASCII Log Data",
  " 1000 80",
  " 1001 82"
)

writeLines(las_text, f)

res <- batch_export_laslogs(
  dir = td,
  out_dir = file.path(td, "exports"),
  county = "TEST",
  curves_any = "GR",
  output = "wide",
  csv = TRUE,
  parquet = FALSE,
  write_index = TRUE
)
names(res)
#> [1] "index"       "apis"        "data"        "paths"       "index_paths"
#> [6] "manifest"   
```
