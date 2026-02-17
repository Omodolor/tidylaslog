# Write LAS logs to CSV and/or Parquet

Write LAS logs to CSV and/or Parquet

## Usage

``` r
write_laslogs(data, out_dir, prefix = "laslogs", csv = TRUE, parquet = TRUE)
```

## Arguments

- data:

  Tibble returned by pull_laslogs()

- out_dir:

  Output directory

- prefix:

  File prefix (no extension)

- csv:

  Write CSV file?

- parquet:

  Write Parquet file? (requires arrow)

## Value

Invisibly returns output paths

## Examples

``` r
out_dir <- tempdir()
df <- data.frame(api = "1111111111", depth = c(1000, 1001), GR = c(80, 82))
paths <- write_laslogs(df, out_dir = out_dir, prefix = "demo", csv = TRUE, parquet = FALSE)
paths
#> $csv
#> [1] "/tmp/RtmpLjDs1i/demo.csv"
#> 
#> $parquet
#> NULL
#> 
```
