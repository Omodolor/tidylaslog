test_that("read_laslog parses example and returns expected components", {
  f <- system.file("extdata", "example.las", package = "tidylaslog")
  expect_true(nchar(f) > 0)

  x <- read_laslog(f, output = "long")

  expect_true(is.list(x))
  expect_true(all(c("VERSION","WELL","CURVE","PARAMETER","OTHER","LOG","null_value","source_file") %in% names(x)))

  # header pieces are tibbles
  expect_s3_class(x$WELL, "tbl_df")
  expect_s3_class(x$CURVE, "tbl_df")

  # LOG in long mode must have these columns
  expect_s3_class(x$LOG, "tbl_df")
  expect_true(all(c("api","county","latitude","longitude","source_file","depth","mnemonic","value") %in% names(x$LOG)))
})

test_that("read_laslog wide output has curve columns", {
  f <- system.file("extdata", "example.las", package = "tidylaslog")
  xw <- read_laslog(f, output = "wide")

  expect_s3_class(xw$LOG, "tbl_df")
  expect_true("depth" %in% names(xw$LOG))
  # at least one curve column besides metadata
  meta <- c("api","county","latitude","longitude","source_file","depth")
  expect_true(any(!names(xw$LOG) %in% meta))
})
