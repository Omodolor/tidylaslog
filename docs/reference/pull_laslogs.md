# Pull log data for selected wells (optionally selected curves)

Pull log data for selected wells (optionally selected curves)

## Usage

``` r
pull_laslogs(index, apis, curves = NULL, output = c("long", "wide"))
```

## Arguments

- index:

  Output of index_laslogs()

- apis:

  Character vector of API values to load

- curves:

  Optional curve mnemonics to keep (e.g., c("GR","RHOB","NPHI"))

- output:

  "long" (tidy) or "wide" (ML-ready)

## Value

A tibble combining all selected wells

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
dat <- pull_laslogs(idx, apis = "1111111111", curves = "GR", output = "long")
head(dat)
#> # A tibble: 0 × 0
```
