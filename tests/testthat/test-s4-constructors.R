test_that("simulatr_function constructs an S4 object", {
  f <- function(x) x + 1
  obj <- simulatr_function(f = f, arg_names = "x", loop = TRUE)
  expect_s4_class(obj, "simulatr_function")
  expect_equal(obj@arg_names, "x")
  expect_true(obj@loop)
})

test_that("simulatr_specifier requires B and seed", {
  f <- function() 1
  data_gen <- simulatr_function(f = f, loop = TRUE)
  expect_error(
    simulatr_specifier(
      parameter_grid = data.frame(),
      fixed_parameters = list(n = 1),
      generate_data_function = data_gen,
      run_method_functions = list()
    )
  )
})

test_that("simulatr_specifier accepts B and seed in fixed_parameters", {
  f <- function() data.frame(x = 1)
  data_gen <- simulatr_function(f = f, loop = TRUE)
  spec <- simulatr_specifier(
    parameter_grid = data.frame(a = 1L),
    fixed_parameters = list(B = 1, seed = 1),
    generate_data_function = data_gen,
    run_method_functions = list()
  )
  expect_s4_class(spec, "simulatr_specifier")
})
