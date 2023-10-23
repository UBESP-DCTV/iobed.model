library(targets)
library(tarchetypes)

list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE) |>
  lapply(source) |> invisible()

# Set target-specific options such as packages.
tar_option_set(
  packages = c("readr", "keras", "tensorflow", "reticulate"),
  resources = tar_resources(
    qs = tar_resources_qs(preset = "fast")
  ),
  garbage_collection = TRUE,
  error = "continue",
  workspace_on_error = TRUE
)

# End this file with a list of target objects.
list(

  tar_files_input(bedFiles, get_bed_file_paths("labelled")),
  tar_target(
    bedData,
    import_bed(bedFiles),
    pattern = map(bedFiles),
    iteration = "list",
    format = "qs"
  ),
  tar_target(
    labelDict,
    c(
      null = 1,
      right = 2,
      center = 3,
      centre = 3,
      supine = 3,
      left = 4,
      transition = 5,
      `slide to the right` = 2,
      `turn to the right` = 2,
      static = 3,
      `slide to the left` = 4,
      `turn to the left` = 4,
      entrance = 5,
      # `entrance to right` = 4,
      # `entrance left` = 5,
      exit = 6,
      # `exit right` = 6,
      # `exit left` = 7,
      `assessment` = 7,
      casual = 8
    )
  ),
  tar_target(
    trainingArrays,
    prepare_supervised_bed(bedData, labelDict),
    pattern = map(bedData),
    iteration = "list",
    format = "qs"
  ),
  tar_target(
    par,
    list(
      x = batch_generator(trainingArrays),
      n_x = batch_generator(trainingArrays)()[[1]][[1]] |>
        (\(x) dim(x)[[1L]])(),
      val = batch_generator(trainingArrays, validation = TRUE),
      n_val = trainingArrays |>
        (\(x) batch_generator(x, validation = TRUE)()[[1]][[1]])() |>
        (\(x) dim(x)[[1L]])(),
      epochs = 2,
      batch_size = trainingArrays |>
        (\(x) batch_generator(x, validation = TRUE)()[[1]][[1]])() |>
        (\(x) dim(x)[[1L]])() |>
        log2() |> # from here: min power of 2 greater then val size
        ceiling() |>
        (\(x) 2^x)(),
      n_timepoints = dim(trainingArrays[[1]][[1]])[[2]] # n timepoints
    ),
    cue = targets::tar_cue("always")
  ),

  tar_target(
    kerasTarget,
    setup_and_fit_model(par),
    format = tar_format(
      read = function(path) {
        keras::load_model_hdf5(path)
      },
      write = function(object, path) {
        keras::save_model_hdf5(object = object, filepath = path)
      },
      marshal = function(object) {
        keras::serialize_model(object)
      },
      unmarshal = function(object) {
        keras::unserialize_model(object)
      }
    ),
    cue = tar_cue("always")
  )

  # compile your report
  # tar_render(report, here::here("reports/report.Rmd")),


  # # Decide what to share with other,
  # # and do it in a standard RDS format
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
