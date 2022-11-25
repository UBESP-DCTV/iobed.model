test_that("get_bed_file_paths works", {
  skip_on_ci()
  skip_on_cran()

  # eval
  bed_files <- get_bed_file_paths()

  # test
  expect_file_exists(bed_files[[1]])
  expect_character(bed_files)
  expect_subset("REDCAP1_bed.xlsx", basename(bed_files))
})

test_that("import_bed works", {
  skip_on_ci()
  skip_on_cran()

  # setup
  bed_path <- targets::tar_read(bedFiles)[[1]]

  # eval
  bed_data <- import_bed(bed_path)

  # test
  expect_tibble(bed_data)

  c("sbl", "weight", "static_bed") |>
    expect_subset(names(bed_data))

  expect_error(
    import_bed(c(bed_path, bed_path)),
    "Must be of length == 1"
  )
})


test_that("prepare_supervised_bed works", {
  skip_on_ci()
  skip_on_cran()

  # setup
  bed_data <- targets::tar_read(bedData, branches = 1)[[1]]

  # eval
  bed_train <- prepare_supervised_bed(bed_data)

  # test
  expect_list(bed_train)
  expect_array(bed_train["x"], "integer", any.missing = FALSE, d = 2)
  expect_gt(dim(bed_train["x"])[1], 0L)
  expect_equal(dim(bed_train["x"])[2], 6L)

  expect_array(bed_train["y"], "integer", any.missing = FALSE, d = 2)
  expect_gt(dim(bed_train["y"])[1], dim(bed_train["x"])[1])
  expect_equal(dim(bed_train["y"])[2], 4L)
})














