setup_and_fit_model <- function(par) {
  stopifnot(
    requireNamespace("reticulate"),
    requireNamespace("tensorflow"),
    requireNamespace("keras")
  )

  k <- reticulate::import("keras", convert = FALSE)

  input <- keras::layer_input(
    name = "input_bed",
    shape = list(NULL, 6)
  )

  hidden_recurrent <-  input %>%
    keras::layer_rescaling(
      name = "rescale_input",
      scale = 1e-3
    ) %>%
    keras::layer_gru(
      name = "oo",
      units = 64,
      return_sequences = TRUE
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "hidden_recurrent",
      units = 64,
      return_sequences = TRUE
    ) %>%
    keras::layer_batch_normalization()

  static_bed <- hidden_recurrent %>%
    keras::layer_gru(
      name = "a",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "aa",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "static_bed_recurrent_output",
      units = 9,
      activation = "softmax"
    )

  dyn_bed <- hidden_recurrent %>%
    keras::layer_gru(
      name = "b",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "bb",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "dyn_bed_recurrent_output",
      units = 9,
      activation = "softmax"
    )

  static_self <- hidden_recurrent %>%
    keras::layer_gru(
      name = "c",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "cc",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "static_self_recurrent_output",
      units = 9,
      activation = "softmax"
    )

  dyn_self <- hidden_recurrent %>%
    keras::layer_gru(
      name = "d",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "dd",
      units = 64,
      return_sequences = TRUE,
      recurrent_dropout = 0.2,
      dropout = 0.2
    ) %>%
    keras::layer_batch_normalization() %>%
    keras::layer_gru(
      name = "dyn_self_recurrent_output",
      units = 9,
      activation = "softmax"
    )

  model <- keras::keras_model(
    inputs = input,
    outputs = list(
      static_bed, dyn_bed, static_self, dyn_self)
  )


  print(model)
  # print(plot(model))

  model %>%
    keras::compile(
      optimizer = k$optimizers$Adam(amsgrad = TRUE),
      loss = list(
        "sparse_categorical_crossentropy", "sparse_categorical_crossentropy",
        "sparse_categorical_crossentropy", "sparse_categorical_crossentropy"
      ),
      metrics = "sparse_categorical_accuracy"
    )

  history <- model %>%
    keras::fit(
      x = par$x,
      steps_per_epoch = par$n_batches,
      validation_data = par$val,
      validation_step = ceiling(par$n_batches / 4),
      batch_size = 20, # 21 people, 1 for validation
      epochs = par$epochs
    )

  print(plot(history))

  list(
    history = history,
    model = model
  )
}

