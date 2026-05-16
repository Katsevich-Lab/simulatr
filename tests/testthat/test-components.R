test_that("simulatr_model construction validates basic slot types", {
  m <- simulatr_model(name = "lm",
                      generate = function(n) data.frame(x = stats::rnorm(n)))
  expect_s4_class(m, "simulatr_model")
  expect_equal(m@name, "lm")
  expect_false(m@batched)
  expect_error(simulatr_model(name = character(0), generate = function() 1),
               "non-empty")
})

test_that("simulatr_method requires at least one formal", {
  expect_error(simulatr_method(name = "bad", run = function() 1),
               "at least one")
})

test_that("simulatr_metric enforces (output, ground_truth) signature", {
  expect_s4_class(
    simulatr_metric(name = "good",
                    score = function(output, ground_truth) 0),
    "simulatr_metric"
  )
  expect_error(
    simulatr_metric(name = "missing_gt", score = function(output) 0),
    "missing"
  )
  expect_error(
    simulatr_metric(name = "extra",
                    score = function(output, ground_truth, extra) 0),
    "unexpected"
  )
})

test_that("simulatr_study requires B and seed, plus arg-name coverage", {
  m <- simulatr_model(name = "g", generate = function(beta_0) data.frame(x = beta_0))
  meth <- simulatr_method(name = "id", run = function(data) data)
  expect_error(
    simulatr_study(
      parameter_grid = data.frame(beta_0 = 1),
      fixed_parameters = list(n = 1),
      models = list(g = m),
      methods = list(id = meth)
    ),
    "B|seed"
  )

  # method asks for a parameter that doesn't exist
  bad_method <- simulatr_method(name = "bad", run = function(data, nope) data)
  expect_error(
    simulatr_study(
      parameter_grid = data.frame(beta_0 = 1),
      fixed_parameters = list(B = 1, seed = 1),
      models = list(g = m),
      methods = list(bad = bad_method)
    ),
    "nope"
  )
})

test_that("simulatr_study accepts a valid spec", {
  m <- simulatr_model(name = "g", generate = function(beta_0, n) data.frame(x = stats::rnorm(n) + beta_0))
  meth <- simulatr_method(name = "id", run = function(data) list(x = data$x))
  study <- simulatr_study(
    parameter_grid = data.frame(beta_0 = 0),
    fixed_parameters = list(n = 5, B = 1, seed = 1),
    models = list(g = m),
    methods = list(id = meth)
  )
  expect_s4_class(study, "simulatr_study")
})
