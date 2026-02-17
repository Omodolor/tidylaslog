# List available curve mnemonics in an index

List available curve mnemonics in an index

## Usage

``` r
available_curves(index, county = NULL, top_n = NULL)
```

## Arguments

- index:

  Output of index_laslogs()

- county:

  Optional county filter (character vector)

- top_n:

  If not NULL, return only the top N most common curves

## Value

Tibble with MNEM and n (count of wells containing the curve)

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
  " RHOB.G/C3:",
  " ~ASCII Log Data",
  " 1000 80 2.35",
  " 1001 82 2.36"
)

writeLines(las_text, f)
idx <- index_laslogs(td)
available_curves(idx, top_n = 5)
#> # A tibble: 4 × 2
#>   MNEM            n
#>   <chr>       <int>
#> 1 DEPT            1
#> 2 GR              1
#> 3 INFORMATION     1
#> 4 RHOB            1
```
