#' get_bed_file_paths
#'
#' Get all the paths to the xlsx files containing bed data and classes
#' to use for classification.
#'
#' @note Input data path is automatically retrieved from the
#'   corresponding entry in the project `.Renviron` files (you can open
#'   it by running `usethis::edit_r_environ("project")`)
#'
#' @return (chr) vector of input xlsx file paths.
#' @export
#'
#' @examples
#' get_bed_file_paths()
get_bed_file_paths <- function() {
  get_input_data_path() |>
    list.files(
      pattern = "((^bed_.+)|(_bed))\\.xlsx$",
      full.names = TRUE
    )
}




#' import_bed
#'
#' Read the xlsx files from disk to a [tibble][tibble::tibble-package].
#'
#' @param bed_path (chr) path to a (single) xlsx file of bed date.
#'
#' @return a [tibble][tibble::tibble-package]
#' @export
#'
#' @examples
#' if (FALSE) {
#'   import_bed("path/to/bed_data.xlsx")
#' }
import_bed <- function(bed_path) {
  checkmate::qassert(bed_path, "S1")
  readxl::read_excel(bed_path)
}




#' prepare_supervised_bed
#'
#' Data from a single IOBED experiments included four weighting sensors
#' reporting the overall weight lying on the bed and the percentage of
#' weight distribution across each of them. In particular thy can be:
#'
#' - **sbl** (Sensor Bottom Left): [0-1000]
#' - **sul** (Sensor Upper Left): [0-1000]
#' - **sbr** (Sensor Bottom Right): [0-1000]
#' - **sur** (Sensor Upper Right): [0-1000]
#' - **weight** (integer hg): e.g. 800 are 80.0 kg
#'
#' Moreover information of the two possible positions of the bed
#' backrest tilt (`tilt_bed`) of 0 or 30 degrees (encoded as 0/1
#' correspondingly).
#'
#'
#'
#' Classification outcome is composed by four pieces of information,
#' i.e.: position (`static`) and dynamics (`dyn`) of the subject wrt the
#' bed (`bed`) or themself (`self`). In particular there are the
#' following classes for each category:
#'
#' - **static_bed**: Center (2), Right (1), Left (3), Transition (-1),
#'     Null (0)
#' - **static_self**: Supine (2), Right (1), Left (3), Transition (-1),
#'     Null (0)
#' - **dyn_bed**: Static (2), Slide to right (1), Slide to left (3),
#'     Entrance Right (4), Entrance Left (5), Exit Right (6),
#'     Exit Left (7), Null (0)
#' - **dyn_self**: Static (2), Turn to right (1), Turn to left (3),
#'     Entrance Right (4), Entrance Left (5), Exit Right (6),
#'     Exit Left (7), Assessment (8), Null (0)
#'
#' @note Time is not reported inside the data because it is supposed
#'   to flow at approximately 300 ms (+- 2 ms)  each row.
#'
#' @note During the experiment people was asked to move randomly on the
#'   bed. in a first phase of the modeling we ignore that portion of
#'   data entirely labelled with `casual`.
#'
#' @param db (data.frame) bed raw data including the sensors information
#'   and the labels for by-row classification.
#' @param include_casual (lgl, default FALSE) include starting "casual"
#'   movement?
#'
#' @return list of two array named "x" and "y_true" containing
#'   respectively the sensors/input data and the true responses for the
#'   classification
#' @export
#'
#' @examples
#' if (FALSE) {
#'  db <- import_bed("path/to/bed_data.xlsx")
#'  db_train <- prepare_supervised_bed(bed)
#' }
prepare_supervised_bed <- function(
    db,
    label_dict,

    include_casual = FALSE
) {
  train_x_vars <- c(
    "tilt_bed", "sbl", "sbr", "sul", "sur", "weight"
  )
  train_x <- dplyr::select(db, dplyr::all_of(train_x_vars)) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        ~tidyr::replace_na(-1) |> as.integer()
      )
    ) |>
    as.matrix()

  train_y_vars <- c("static_bed", "dyn_bed", "static_self", "dyn_self")
  train_y <- dplyr::select(db, dplyr::all_of(train_y_vars)) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::everything(),
        ~tolower(.x) |> tidyr::replace_na("(missing)")
      )
    ) |>
    purrr::map(~{
      label_dict[.x] |>
        as.integer() |>
        array(dim = c(1, length(.x)))
    }) |>
    purrr::set_names(
      c(
        "static_bed_recurrent_output",
        "dyn_bed_recurrent_output",
        "static_self_recurrent_output",
        "dyn_self_recurrent_output"
      )
    )


  list(
    input_bed = train_x |>
        array(dim = c(nrow(train_x), ncol(train_x))) |>
        abind::abind(along = 0.5),
    targets = train_y
  )
}


batch_generator <- function(training_list, validation = FALSE) {
  i <- 1

  slice_time <- function(x, i, seq = FALSE) {
    if ((length(dim(x)) == 3)) {
      x[, seq_len(i), , drop = FALSE]
    } else {
      if (seq) {
        x[, seq_len(i), drop = FALSE]
      } else {
        x[, i, drop = FALSE]
      }
    }
  }

  max_len <- training_list |>
    purrr::map_int(~dim(.x[[1]])[[2]]) |>
    min()

  training_list <- training_list |>
    purrr::map(~{
      list(
        slice_time(.x[[1]], max_len),
        purrr::map(.x[[2]], slice_time, max_len, seq = TRUE) |>
          purrr::set_names(
            c(
              "static_bed_recurrent_output",
              "dyn_bed_recurrent_output",
              "static_self_recurrent_output",
              "dyn_self_recurrent_output"
            )
          )
      )
    })


  training_list <- if (validation) {
    training_list[[1]]
  } else {
    aux <- training_list[-1]
    aux_x <- purrr::map(aux, 1) |> abind::abind(along = 1)
    aux_y1 <- purrr::map(aux, c(2, 1)) |>
      abind::abind(along = 1)
    aux_y2 <- purrr::map(aux, c(2, 2)) |>
      abind::abind(along = 1)
    aux_y3 <- purrr::map(aux, c(2, 3)) |>
      abind::abind(along = 1)
    aux_y4 <- purrr::map(aux, c(2, 4)) |>
      abind::abind(along = 1)

    list(
      aux_x,
      list(aux_y1, aux_y2, aux_y3, aux_y4)
    )
  }

  function() {
    if (i > dim(training_list[[1]])[[2]]) i <<- 1

    res_x <- list(input_bed = slice_time(training_list[[1]], i))

    res_y <- training_list[[2]] |>
          purrr::map(slice_time, i) |>
          purrr::set_names(
            c(
              "static_bed_recurrent_output",
              "dyn_bed_recurrent_output",
              "static_self_recurrent_output",
              "dyn_self_recurrent_output"
            )
          )

    i <<- i + 1

    list(
      x = res_x,
      y_true = res_y
    )
  }
}
