# Drive the simulatr_study validity branches that aren't already exercised
# elsewhere — unresolvable model formals, unresolvable method formals,
# wrong list-element types, and missing B / seed.

bad_model <- simulatr_model(
  name     = "bad_model",
  generate = function(n, unknown_arg) list(x = n + unknown_arg)
)

ok_model <- simulatr_model(
  name     = "ok_model",
  generate = function(n) list(x = rnorm(n))
)

ok_method <- simulatr_method(
  name = "ok_method",
  run  = function(data) list(mean = mean(data$x))
)

bad_method <- simulatr_method(
  name = "bad_method",
  run  = function(data, undeclared) list(out = undeclared)
)

ok_metric <- simulatr_metric(
  name  = "ok_metric",
  score = function(output, ground_truth) abs(output$mean - 0)
)

base_grid <- data.frame(n = c(5L, 10L))

test_that("model formal not in grid/fixed errors with a clear pointer", {
  expect_error(
    simulatr_study(
      parameter_grid   = base_grid,
      fixed_parameters = list(B = 2L, seed = 1L),
      models = list(bad = bad_model),
      methods = list(ok = ok_method),
      metrics = list(ok = ok_metric)
    ),
    regexp = "bad_model.*unknown_arg|unknown_arg"
  )
})

test_that("method formal not in grid/fixed errors with a clear pointer", {
  expect_error(
    simulatr_study(
      parameter_grid   = base_grid,
      fixed_parameters = list(B = 2L, seed = 1L),
      models = list(ok = ok_model),
      methods = list(bad = bad_method),
      metrics = list(ok = ok_metric)
    ),
    regexp = "bad_method.*undeclared|undeclared"
  )
})

test_that("missing B in fixed_parameters errors", {
  expect_error(
    simulatr_study(
      parameter_grid   = base_grid,
      fixed_parameters = list(seed = 1L),
      models = list(ok = ok_model),
      methods = list(ok = ok_method)
    ),
    regexp = "`B`"
  )
})

test_that("missing seed in fixed_parameters errors", {
  expect_error(
    simulatr_study(
      parameter_grid   = base_grid,
      fixed_parameters = list(B = 2L),
      models = list(ok = ok_model),
      methods = list(ok = ok_method)
    ),
    regexp = "`seed`"
  )
})

test_that("empty models errors", {
  expect_error(
    simulatr_study(
      parameter_grid   = base_grid,
      fixed_parameters = list(B = 2L, seed = 1L),
      models = list(),
      methods = list(ok = ok_method)
    ),
    regexp = "models.*at least one"
  )
})

test_that("non-simulatr_model in models errors", {
  expect_error(
    simulatr_study(
      parameter_grid   = base_grid,
      fixed_parameters = list(B = 2L, seed = 1L),
      models = list(bogus = list(name = "bogus")),
      methods = list(ok = ok_method)
    ),
    regexp = "models.*simulatr_model"
  )
})

test_that("non-simulatr_metric in metrics errors", {
  expect_error(
    simulatr_study(
      parameter_grid   = base_grid,
      fixed_parameters = list(B = 2L, seed = 1L),
      models = list(ok = ok_model),
      methods = list(ok = ok_method),
      metrics = list(bogus = function(output, ground_truth) 0)
    ),
    regexp = "metrics.*simulatr_metric"
  )
})

test_that("print.simulatr_session_info renders without error", {
  info <- simulatr_session_info()
  expect_output(print(info), "simulatr_session_info")
  expect_output(print(info), "contract version")
  expect_output(print(info), "contract hash")
})
