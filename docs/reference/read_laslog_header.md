# Read LAS header only (no ~A data)

Read LAS header only (no ~A data)

## Usage

``` r
read_laslog_header(file)
```

## Arguments

- file:

  Path to a .las file

## Value

S3 object of class "laslog_header" with
VERSION/WELL/CURVE/PARAMETER/OTHER plus provenance

## Examples

``` r
las_text <- c(
  " ~Version Information",
  " VERS. 2.0: CWLS LOG ASCII STANDARD",
  " WRAP. NO:",
  " ~Well Information",
  " STRT.M 1000: Start depth",
  " STOP.M 1001: Stop depth",
  " STEP.M 1: Step",
  " NULL. -999.25: Null value",
  " API . 1111111111: API number",
  " CNTY. TEST: County",
  " ~Curve Information",
  " DEPT.M: Depth",
  " GR.API: Gamma Ray",
  " ~ASCII Log Data",
  " 1000 80",
  " 1001 82"
)
f <- tempfile(fileext = ".las")
writeLines(las_text, f)
h <- read_laslog_header(f)
names(h)
#> [1] "VERSION"     "WELL"        "CURVE"       "PARAMETER"   "OTHER"      
#> [6] "null_value"  "source_file"
```
