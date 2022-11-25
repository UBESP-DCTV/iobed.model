## Use this script to run exploratory code maybe before to put it into
## the pipeline


# setup -----------------------------------------------------------

library(targets)
library(here)

# load all your custom functions
list.files(here("R"), pattern = "\\.R$", full.names = TRUE) |>
  lapply(source) |> invisible()


# Code here below -------------------------------------------------
# use `tar_read(target_name)` to load a target anywhere (note that
# `target_name` is NOT quoted!)

tar_read(bedFiles)


tar_read(bedData, branches = 1) |> class()
tar_read(bedData, branches = 1)[[1]] |> class()
tar_read(bedData, branches = 2)

tar_read(bedData) |> class()
