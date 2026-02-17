# Select wells from an index by metadata and curve availability

Select wells from an index by metadata and curve availability

## Usage

``` r
select_laslogs(index, county = NULL, curves_any = NULL, curves_all = NULL)
```

## Arguments

- index:

  Output of index_laslogs()

- county:

  Character vector of counties to keep (optional)

- curves_any:

  Keep wells that have at least one of these curves (optional)

- curves_all:

  Keep wells that have all of these curves (optional)

## Value

Character vector of API values

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
idx <- index_laslogs(td)
apis <- select_laslogs(idx, county = "TEST", curves_any = "GR")
apis
#> [1] "1111111111" "2222222222"
```
