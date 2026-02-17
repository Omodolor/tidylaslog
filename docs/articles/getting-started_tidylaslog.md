# tidylaslog

Methods

tidylaslog provides tools for reading, parsing, indexing, and exporting
LAS (Log ASCII Standard) well log files into tidy, analysis-ready
tabular formats. The workflow is designed for folder-based LAS
collections where each file contains both header metadata (e.g., API and
county) and depth-indexed log curves (e.g., GR, RHOB, NPHI).

A FAIR-style index is first built across the LAS directory
(index_laslogs()), enabling fast discovery of available wells and
curves. Wells can then be selected by metadata and curve availability
(select_laslogs()), and log data are pulled for only the selected wells
(pull_laslogs()), returning either wide (machine-learning ready) or long
(tidy) formats.

For end-to-end reproducibility, tidylaslog() and batch_export_laslogs()
can index, filter, pull, and export logs to CSV and/or Parquet in one
call, with optional index tables and a manifest for provenance tracking.

Justification

This approach is appropriate because large LAS collections are rarely
analysis-ready in their raw state: wells vary in header completeness,
curve availability, and naming conventions. A directory-level index
makes the collection searchable and reproducible, supports transparent
filtering decisions (e.g., keep only wells in a county or wells
containing GR), and avoids repeatedly re-reading the full dataset.

Returning both long and wide representations supports complementary
workflows: long format for tidy analysis/visualization and wide format
for modeling and machine learning. Exporting to CSV/Parquet enables
scalable downstream use in earth science, statistics, and ML pipelines
while preserving tidy data principles (Wickham, 2014).

Short “how it was done”

Pointed tidylaslog to a directory containing .las files

Built an index (index_laslogs()) to summarize wells, curves, and
provenance

Inspected available curves (available_curves())

Selected wells using county and curve criteria (select_laslogs())

Pulled stacked log data for selected APIs (pull_laslogs()), in wide or
long format

Exported tables to CSV and/or Parquet (write_laslogs() or export mode
via tidylaslog() / batch_export_laslogs())

``` r
knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)
```

Setup

``` r
library(tidylaslog)
library(dplyr)
```

Example 1: Directory workflow (index → select → pull) 1) Directory path
(real data)

``` r
dir <- "~/CSE_MSE_RXF131/staging/sdle/geospatial/Columbiana_wells/Las_new"
# stopifnot(dir.exists(dir))  # uncomment when running on your machine
dir
```

    ## [1] "~/CSE_MSE_RXF131/staging/sdle/geospatial/Columbiana_wells/Las_new"

2.  Build index (FAIR-style)

``` r
idx <- index_laslogs(dir)
names(idx)
```

    ## [1] "wells_index"  "curves_index" "files_index"

``` r
# Preview index tables
dplyr::glimpse(idx$wells_index)
```

    ## Rows: 20
    ## Columns: 11
    ## $ api         <chr> "34019202560000", "34019202860000", "34019204460000", "340…
    ## $ uwi         <chr> "34019202560000", "34019202860000", "34019204460000", "340…
    ## $ county      <chr> "CARROLL", "CARROLL", "CARROLL", "CARROLL", "CARROLL", "CA…
    ## $ state       <chr> "OH", "OHIO", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "O…
    ## $ latitude    <dbl> 40.71608, 40.65772, 40.61004, 40.61121, 40.60654, 40.58934…
    ## $ longitude   <dbl> -81.40730, -81.10764, -81.24135, -81.30859, -80.98532, -81…
    ## $ well        <chr> "#4-455", "#1", "#3", "#4", "#1", "#1", "COMM", "#1", "#1-…
    ## $ company     <chr> "#15", "INCORPORATED", "LTD", "#10A", "CORP.", "GAS", "COM…
    ## $ null_value  <dbl> -999.25, -999.25, -999.25, -999.25, -999.25, -999.25, -999…
    ## $ source_file <chr> "34019202560000.las", "34019202860000.las", "3401920446000…
    ## $ file_path   <chr> "/home/hxo76/CSE_MSE_RXF131/staging/sdle/geospatial/Columb…

``` r
dplyr::glimpse(idx$curves_index)
```

    ## Rows: 130
    ## Columns: 8
    ## $ api         <chr> "34019202560000", "34019202560000", "34019202560000", "340…
    ## $ county      <chr> "CARROLL", "CARROLL", "CARROLL", "CARROLL", "CARROLL", "CA…
    ## $ source_file <chr> "34019202560000.las", "34019202560000.las", "3401920256000…
    ## $ file_path   <chr> "/home/hxo76/CSE_MSE_RXF131/staging/sdle/geospatial/Columb…
    ## $ MNEM        <chr> "DEPT", "RHOB", "FDC", "GR", "NEUT", "DEPT", "GR", "RHOB",…
    ## $ UNIT        <chr> "FT", "", "", "", "N", "FT", "", "G/C3", "IN", "FT", "", "…
    ## $ API_CODE    <chr> "", ".G/C3", ".CPS 42 350 01 01", ".GAPI 35 310 01 01", "3…
    ## $ DESC        <chr> "Depth in Feet", "Bulk Density", "", "Gamma Ray", "Neutron…

``` r
dplyr::glimpse(idx$files_index)
```

    ## Rows: 20
    ## Columns: 3
    ## $ api         <chr> "34019202560000", "34019202860000", "34019204460000", "340…
    ## $ file_path   <chr> "/home/hxo76/CSE_MSE_RXF131/staging/sdle/geospatial/Columb…
    ## $ source_file <chr> "34019202560000.las", "34019202860000.las", "3401920446000…

3.  What curves exist in this collection?

``` r
available_curves(idx, top_n = 20)
```

    ## # A tibble: 20 × 2
    ##    MNEM      n
    ##    <chr> <int>
    ##  1 DEPT     20
    ##  2 GR       19
    ##  3 RHOB     17
    ##  4 CALI     12
    ##  5 NEUT      7
    ##  6 NPHI      6
    ##  7 DPHI      3
    ##  8 DPOR      2
    ##  9 ILD       2
    ## 10 PEF       2
    ## 11 AVOL      1
    ## 12 BIT       1
    ## 13 CAL       1
    ## 14 CLDC      1
    ## 15 DCOR      1
    ## 16 DDLL      1
    ## 17 DEN       1
    ## 18 DOL       1
    ## 19 DPRD      1
    ## 20 DPRL      1

4.  Select wells by metadata and curve availability

Example: keep wells in Columbiana County that have at least one of
GR/RHOB.

``` r
apis <- select_laslogs(
  index = idx,
  county = c("COLUMBIANA"),
  curves_any = c("GR", "RHOB")
)

length(apis)
```

    ## [1] 5

``` r
head(apis)
```

    ## [1] "34029206070000" "34029206560000" "34029206680000" "34029214760000"
    ## [5] "34029216370000"

5.  Pull logs for selected wells (wide or long)

Wide format (ML/spreadsheet-ready):

``` r
logs_wide <- pull_laslogs(
  index  = idx,
  apis   = apis,
  curves = c("GR", "RHOB"),
  output = "wide"
)
dplyr::glimpse(logs_wide)
```

    ## Rows: 74,105
    ## Columns: 8
    ## $ api         <chr> "34029206070000", "34029206070000", "34029206070000", "340…
    ## $ county      <chr> "COLUMBIANA", "COLUMBIANA", "COLUMBIANA", "COLUMBIANA", "C…
    ## $ latitude    <dbl> 40.78508, 40.78508, 40.78508, 40.78508, 40.78508, 40.78508…
    ## $ longitude   <dbl> -80.85105, -80.85105, -80.85105, -80.85105, -80.85105, -80…
    ## $ source_file <chr> "34029206070000.las", "34029206070000.las", "3402920607000…
    ## $ depth       <dbl> 500.0, 500.5, 501.0, 501.5, 502.0, 502.5, 503.0, 503.5, 50…
    ## $ GR          <dbl> 72.21116, 72.21116, 74.20319, 75.19920, 76.19522, 76.19522…
    ## $ RHOB        <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…

Long format (tidy):

``` r
logs_long <- pull_laslogs(
  index  = idx,
  apis   = apis,
  curves = c("GR", "RHOB"),
  output = "long"
)
dplyr::glimpse(logs_long)
```

    ## Rows: 146,809
    ## Columns: 8
    ## $ api         <chr> "34029206070000", "34029206070000", "34029206070000", "340…
    ## $ county      <chr> "COLUMBIANA", "COLUMBIANA", "COLUMBIANA", "COLUMBIANA", "C…
    ## $ latitude    <dbl> 40.78508, 40.78508, 40.78508, 40.78508, 40.78508, 40.78508…
    ## $ longitude   <dbl> -80.85105, -80.85105, -80.85105, -80.85105, -80.85105, -80…
    ## $ source_file <chr> "34029206070000.las", "34029206070000.las", "3402920607000…
    ## $ depth       <dbl> 500.0, 500.0, 500.5, 500.5, 501.0, 501.0, 501.5, 501.5, 50…
    ## $ mnemonic    <chr> "GR", "RHOB", "GR", "RHOB", "GR", "RHOB", "GR", "RHOB", "G…
    ## $ value       <dbl> 72.21116, NA, 72.21116, NA, 74.20319, NA, 75.19920, NA, 76…

QC Number of files / wells

``` r
n_files <- nrow(idx$files_index)
n_wells <- nrow(idx$wells_index)

n_files
```

    ## [1] 20

``` r
n_wells
```

    ## [1] 20

Missingness summary (wide table)

``` r
missing_pct <- sapply(logs_wide, function(x) mean(is.na(x)) * 100)

missing_summary <- tibble(
  variable = names(missing_pct),
  missing_percent = as.numeric(missing_pct)
) %>%
  arrange(desc(missing_percent))

head(missing_summary, 20)
```

    ## # A tibble: 8 × 2
    ##   variable    missing_percent
    ##   <chr>                 <dbl>
    ## 1 RHOB                  52.9 
    ## 2 GR                     7.88
    ## 3 api                    0   
    ## 4 county                 0   
    ## 5 latitude               0   
    ## 6 longitude              0   
    ## 7 source_file            0   
    ## 8 depth                  0

Export (CSV and/or Parquet)

``` r
out_dir <- file.path(dir, "exports_tidylaslog")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

paths <- write_laslogs(
  data    = logs_wide,
  out_dir = out_dir,
  prefix  = "columbiana_GR_RHOB_wide",
  csv     = TRUE,
  parquet = FALSE   # set TRUE if arrow is installed
)

paths
```

    ## $csv
    ## [1] "/home/hxo76/CSE_MSE_RXF131/staging/sdle/geospatial/Columbiana_wells/Las_new/exports_tidylaslog/columbiana_GR_RHOB_wide.csv"
    ## 
    ## $parquet
    ## NULL

Example 2: One-call pipeline (index + filter + export)

``` r
res <- batch_export_laslogs(
  dir = dir,
  out_dir = out_dir,
  county = c("COLUMBIANA"),
  curves_any = c("GR", "RHOB"),
  output = "wide",
  csv = TRUE,
  parquet = FALSE,
  write_index = TRUE
)

names(res)
```

    ## [1] "index"       "apis"        "data"        "paths"       "index_paths"
    ## [6] "manifest"

Example 3: Universal entry point (tidylaslog)

``` r
res2 <- tidylaslog(
  x = dir,
  county = c("COLUMBIANA"),
  curves_any = c("GR"),
  output = "wide",
  out_dir = out_dir,
  formats = "csv",
  write_index = TRUE,
  manifest = TRUE
)

names(res2)
```

    ## [1] "index"       "apis"        "data"        "paths"       "index_paths"
    ## [6] "manifest"
