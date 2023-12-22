## Use this script to run exploratory code maybe before to put it into
## the pipeline


# setup -----------------------------------------------------------

library(targets)
library(here)

library(reticulate)
library(tensorflow)
library(keras)

# load all your custom functions
list.files(here("R"), pattern = "\\.R$", full.names = TRUE) |>
  lapply(source) |> invisible()


# Code here below -------------------------------------------------
# use `tar_read(target_name)` to load a target anywhere (note that
# `target_name` is NOT quoted!)

tar_read(trainingArray, branches = 1)[[1]] |> View()
tar_read(trainingArray, branches = 2)[[1]]

bd <- tar_read(bedData)[[1]]
ta <- tar_read(trainingArrays)
str(ta)
# ld <- tar_read(labelDict)





i <- 6
ta$trainingArrays_c637d723$input_bed |>
  slice_time(i)
ta$trainingArrays_c637d723$targets |>
  purrr::map(slice_time, i)



bg <- batch_generator(ta)
bbg <- batch_generator(tb)

a <- bg()
str(a)

a <- sb[[1]]
a
str(a)
abind::abind(a, along = 0.5) |> str()


par <- tar_r

model <- tar_read(kerasTarget)

res <- predict(model, ta[[1]][[1]])

str(res)

str(ta)

hist(res[[1]])
hist(res[[2]])



res <- setup_and_fit_model(targets::tar_read(par))
