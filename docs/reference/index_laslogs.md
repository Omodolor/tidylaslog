# Build a FAIR index for a folder of LAS files

Build a FAIR index for a folder of LAS files

## Usage

``` r
index_laslogs(dir)
```

## Arguments

- dir:

  Folder containing .las files

## Value

A list with wells_index, curves_index, files_index

## Examples

``` r
td <- tempdir()
f1 <- file.path(td, "a.las")
f2 <- file.path(td, "b.las")

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

writeLines(las_text, f1)
writeLines(sub("1111111111", "2222222222", las_text), f2)

idx <- index_laslogs(td)
names(idx)
#> [1] "wells_index"  "curves_index" "files_index" 
```
