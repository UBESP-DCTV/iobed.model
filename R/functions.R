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
      pattern = "_bed\\.xlsx",
      full.names = TRUE
    )
}




import_bed <- function(bed_path) {
  readxl::read_excel(bed_path)
}
