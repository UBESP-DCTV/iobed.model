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
  bed_path <- get_bed_file_paths()[[1]]

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
  bed_data <- targets::tar_read(bedData, branches = 2)[[1]]
  bed_data_miss <- targets::tar_read(bedData, branches = 1)[[1]]
  label_dict <- targets::tar_read(labelDict)

  # eval
  bed_train <- prepare_supervised_bed(bed_data, label_dict)
  bed_train_miss <- prepare_supervised_bed(bed_data_miss, label_dict)

  # test
  expect_list(bed_train)
  bed_train[["x"]] |>
    expect_array("integer", any.missing = FALSE, d = 2)
  expect_gt(dim(bed_train[["x"]])[1], 0L)
  expect_equal(dim(bed_train[["x"]])[2], 6L)

  bed_train[["y_true"]] |>
    expect_array("integer", any.missing = FALSE, d = 2)
  expect_gte(dim(bed_train[["y_true"]])[1], dim(bed_train[["x"]])[1])
  expect_equal(dim(bed_train[["y_true"]])[2], 4L)

  expect_equal(bed_train[["y_true"]][63], 9)
  expect_equal(bed_train_miss[["y_true"]][1], -1)
})
