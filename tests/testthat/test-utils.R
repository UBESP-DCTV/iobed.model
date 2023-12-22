test_that("extract_fct_names works", {
  # setup
  funs <- "
  a <- function() {}
  b <- 2
  c<- function() {}
  d <-function() {}
  `%||%` <- function() {}
  "
  withr::local_file("funs.R")
  fs::file_exists("funs.R")
  readr::write_lines(funs, "funs.R")
  readr::read_lines("funs.R")
  # execution
  res <- extract_fct_names("funs.R")

  # expectation
  expect_equal(res, c("a", "c", "d", "%||%"))
})


test_that("slice time works", {
  # setup
  a <- array(1:6, dim = c(1, 6, 1))
  b <- array(1:6, dim = c(1, 6))

  # eval
  a3 <- slice_time(a, 3)
  a5 <- slice_time(a,5)
  b3 <- slice_time(a, 3)
  b5 <- slice_time(a,5)

  # test
  expect_equal(a3, array(1:3, dim = c(1, 3, 1)))
  expect_equal(a5, array(1:5, dim = c(1, 5, 1)))
  expect_equal(b3, array(1:3, dim = c(1, 3)))
  expect_equal(b5, array(1:5, dim = c(1, 5)))
})
