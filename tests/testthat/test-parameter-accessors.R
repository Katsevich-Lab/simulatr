test_that("get_param_from_simulatr_spec resolves from grid and fixed params", {
  spec <- make_simple_spec(B = 2, rng_method = FALSE)
  expect_equal(get_param_from_simulatr_spec(spec, 1, "beta_0"), 0)
  expect_equal(get_param_from_simulatr_spec(spec, 1, "n"), 30)
  expect_equal(get_param_from_simulatr_spec(spec, NULL, "B"), 2)
  expect_error(get_param_from_simulatr_spec(spec, 1, "nope"))
})

test_that("update_B_sim_spec updates B in fixed_parameters", {
  spec <- make_simple_spec(B = 2, rng_method = FALSE)
  spec2 <- update_B_sim_spec(spec, 10)
  expect_equal(get_param_from_simulatr_spec(spec2, NULL, "B"), 10)
})

test_that("get_ordered_args returns positional list", {
  spec <- make_simple_spec(B = 2, rng_method = FALSE)
  args <- get_ordered_args(spec@generate_data_function, spec, 1)
  expect_length(args, length(spec@generate_data_function@arg_names))
  expect_equal(args[[1]], 0) # beta_0
})

test_that("get_params_for_nextflow writes a parseable file", {
  spec <- make_simple_spec(B = 2, rng_method = FALSE)
  tf <- tempfile()
  on.exit(unlink(tf), add = TRUE)
  get_params_for_nextflow(spec, tf, B_in = 0)
  lines <- readLines(tf)
  expect_true(any(grepl("^method_names:", lines)))
  expect_true(any(grepl("^n_param_settings:", lines)))
})
