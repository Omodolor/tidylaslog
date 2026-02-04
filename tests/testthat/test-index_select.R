test_that("index_laslogs builds an index and select_laslogs filters", {
  d <- system.file("extdata", package = "tidylaslog")
  expect_true(nchar(d) > 0)

  idx <- index_laslogs(d)

  expect_true(is.list(idx))
  expect_true(all(c("wells_index","curves_index","files_index") %in% names(idx)))

  expect_s3_class(idx$wells_index, "tbl_df")
  expect_s3_class(idx$curves_index, "tbl_df")
  expect_s3_class(idx$files_index, "tbl_df")

  # select by curves that should exist in example.las
  apis <- select_laslogs(idx, curves_any = c("GR"))
  expect_true(is.character(apis))
  expect_true(length(apis) >= 1)
})
