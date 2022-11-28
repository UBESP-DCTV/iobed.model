library(targets)
library(tarchetypes)

list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE) |>
  lapply(source) |> invisible()

# Set target-specific options such as packages.
tar_option_set(
  packages = c("readr", "keras", "tensorflow", " reticulate"),
  resources = tar_resources(
    qs = tar_resources_qs(preset = "fast")
  ),
  garbage_collection = TRUE,
  error = "continue",
  workspace_on_error = TRUE
)

# End this file with a list of target objects.
list(

  tar_files_input(bedFiles, get_bed_file_paths()),
  tar_target(
    bedData,
    import_bed(bedFiles),
    pattern = map(bedFiles),
    iteration = "list",
    format = "qs"
  ),
  tar_target(
    trainingArray,
    prepare_supervised_bed(bedData, labelDict),
    pattern = map(bedData),
    iteration = "list",
    format = "qs"
  ),
  tar_target(
    labelDict,
    c(
      `(missing)` = -1,
      null = 0,
      right = 1,
      center = 2,
      left = 3,
      transition = 4,
      `slide to right` = 1,
      `turn to right` = 1,
      static = 2,
      `slide to left` = 3,
      `turn to left` = 3,
      entrance = 4,
      # `entrance to right` = 4,
      # `entrance left` = 5,
      exit = 6,
      # `exit right` = 6,
      # `exit left` = 7,
      `assessment` = 8,
      casual = 9
    )
  )

  # compile your report
  # tar_render(report, here::here("reports/report.Rmd")),


  # # Decide what to share with other, and do it in a standard RDS format
  # tar_target(
  #   objectToShare,
  #   list(
  #     relevant_result =
  #   )
  # ),
  # tar_target(
  #   shareOutput,
  #   share_objects(objectToShare),
  #   format = "file",
  #   pattern = map(objectToShare)
  # )
)
