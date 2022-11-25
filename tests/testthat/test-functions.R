test_that("get_bed_file_paths works", {
  skip_on_ci()

  # eval
  bed_files <- get_bed_file_paths()

  # test
  expect_file_exists(bed_files[[1]])
  expect_character(bed_files)
  expect_subset("REDCAP1_bed.xlsx", basename(bed_files))
})

test_that("import_bed works", {
  skip_on_ci()

  # setup
  bed_path <- targets::tar_read(bedFiles)[[1]]

  # eval
  bed_data <- import_bed(bed_path)

  # test
  expect_tibble(bed_data)

  c("sbl", "weight", "static_bed") |>
    expect_subset(names(bed_data))
})

