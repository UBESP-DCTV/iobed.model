library(tidyverse)
library(readxl)
library(janitor)

source_folder <- get_input_data_path() |>
  file.path("../../Labels/data-raw/REDCAP_MRG") |>
  normalizePath()

dest_folder <- get_input_data_path("labelled")


folders_to_consider <- source_folder |>
  file.path("REDCAP_FileRecap.xlsx") |>
  read_xlsx() |>
  clean_names() |>
  remove_empty(c("rows", "cols")) |>
  filter(
    if_all(bilancia:excel, ~ str_to_lower(.x) == "ok"),
    is.na(note)
  ) |>
  pull(soggetto)


source_folder |>
  list.dirs(recursive = FALSE) |>
  str_subset(paste(folders_to_consider, collapse = "$|")) |>
  (\(x) set_names(x, basename(x)))() |>
  map(
    list.files,
    pattern = "(_SM\\.xlsx$)|(_MRG\\.xlsx$)",
    full.names = TRUE
  ) |>
  vctrs::list_drop_empty() |>
  walk(
    fs::file_copy,
    new_path = dest_folder,
    overwrite = TRUE
  )

get_xlsx <- function(dest_folder) {
  dest_folder |>
    list.files(full.names = TRUE) |>
    (\(x) set_names(x, basename(x)))() |>
    map(~ read_xlsx(.x) |> janitor::remove_empty(c("rows", "cols")))
}

files_to_delete <- dest_folder |>
  list.files(full.names = TRUE) |>
  (\(x) x[
    get_xlsx(dest_folder) |>
      map_lgl(~(ncol(.x) != 13) | ("note" %in% names(.x)))
  ])()

fs::file_delete(files_to_delete)

is_debug <- FALSE
if (is_debug) {
  labelled_xlsx <- get_xlsx(dest_folder)
}
