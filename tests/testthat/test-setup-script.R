test_that("setup_script returns spec and ordered args, and sets the seed", {
  spec <- make_simple_spec(B = 2, rng_method = FALSE)
  res <- setup_script(spec, B_in = 0, function_object = spec@generate_data_function, row_idx = 1)
  expect_named(res, c("simulatr_spec", "ordered_args"))
  expect_length(res$ordered_args, length(spec@generate_data_function@arg_names))
})

test_that("collate_result_list adds proc_id, grid_id, method, and id", {
  df <- data.frame(parameter = "beta_1", target = "Estimate", value = 1.0, run_id = 1)
  out <- collate_result_list(df, proc_id = 2, row_idx = 3, method = "lm")
  expect_true(all(c("proc_id", "grid_id", "method", "id") %in% colnames(out)))
  expect_equal(as.character(out$method[[1]]), "lm")
  expect_equal(out$proc_id[[1]], 2)
  expect_equal(out$grid_id[[1]], 3)
})
