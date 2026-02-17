# Read a LAS well log file (Log ASCII Standard) into a structured object

tidylaslog supports two equivalent representations of LAS log data:

## Usage

``` r
read_laslog(file, output = c("long", "wide"))
```

## Arguments

- file:

  Path to a .las file

- output:

  Output format:

  "wide"

  :   One row per depth per well, curves as columns (ML- and
      spreadsheet-ready).

  "long"

  :   One row per curve measurement with columns depth, mnemonic, and
      value (tidy format).

## Value

An S3 object of class "laslog" with
VERSION/WELL/CURVE/PARAMETER/OTHER/LOG

## Details

- **Wide format**: one row per depth step per well, with each curve
  stored as a separate column.

- **Long format**: one row per measurement, with curve names stored in a
  `mnemonic` column and values in a `value` column.

Both formats contain the same information but are optimized for
different workflows.

## Examples

``` r
las_text <- c(
  " ~Version Information",
  " VERS. 2.0: CWLS LOG ASCII STANDARD",
  " WRAP. NO:",
  " ~Well Information",
  " STRT.M 1000: Start depth",
  " STOP.M 1002: Stop depth",
  " STEP.M 1: Step",
  " NULL. -999.25: Null value",
  " API . 1111111111: API number",
  " CNTY. TEST: County",
  " ~Curve Information",
  " DEPT.M: Depth",
  " GR.API: Gamma Ray",
  " ~ASCII Log Data",
  " 1000 80",
  " 1001 82",
  " 1002 79"
)
f <- tempfile(fileext = ".las")
writeLines(las_text, f)
x <- read_laslog(f, output = "long")
head(x$LOG)
#> # A tibble: 0 × 0
```
