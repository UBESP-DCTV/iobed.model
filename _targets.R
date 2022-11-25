library(targets)
library(tarchetypes)

list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE) |>
  lapply(source) |> invisible()

# Set target-specific options such as packages.
tar_option_set(
  packages = c("readr"),
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
