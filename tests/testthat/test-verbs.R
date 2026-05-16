test_that("simulatr_generate produces one draw per (grid_row, run_id)", {
  study <- make_simple_study(B = 3, rng_method = FALSE)
  draws <- simulatr_generate(study)
  expect_equal(nrow(draws), nrow(study@parameter_grid) * 3L)
  expect_named(draws, c("grid_id", "run_id", "chunk_id", "draws"))
  expect_true(is.integer(draws$grid_id))
  expect_true(is.integer(draws$run_id))
  expect_true(is.list(draws$draws))
})

test_that("simulatr_run (interleaved default) returns outputs for every method", {
  study <- make_simple_study(B = 3, rng_method = TRUE)
  outputs <- simulatr_run(study)
  expect_named(outputs, c("grid_id", "method", "chunk_id", "run_id", "output"))
  # one row per (grid row, method, run_id)
  expect_equal(nrow(outputs), nrow(study@parameter_grid) * length(study@methods) * 3L)
  expect_true(all(c("lm", "rand") %in% unique(outputs$method)))
})

test_that("simulatr_run accepts pre-computed draws", {
  study <- make_simple_study(B = 2, rng_method = FALSE)
  draws <- simulatr_generate(study)
  outputs <- simulatr_run(study, draws = draws)
  expect_equal(nrow(outputs), nrow(study@parameter_grid) * length(study@methods) * 2L)
})

test_that("simulatr_evaluate and summarise produce frozen-schema tibbles", {
  metric_beta1_bias <- simulatr_metric(
    name = "beta1_bias",
    score = function(output, ground_truth) {
      output$beta_1 - ground_truth$beta_1
    }
  )
  study <- make_simple_study(B = 4, rng_method = FALSE)
  study@metrics <- list(beta1_bias = metric_beta1_bias)
  outputs <- simulatr_run(study)
  evals <- simulatr_evaluate(study, outputs)
  expect_named(evals, c("grid_id", "method", "metric", "run_id", "value"))
  expect_equal(nrow(evals), nrow(outputs))

  summ <- simulatr_evals_summarise(evals)
  expect_named(summ, c("grid_id", "method", "metric", "mean", "se", "n"))
  expect_true(all(summ$n == 4L))
})

test_that("simulatr_check returns a list of three tibbles", {
  study <- make_simple_study(B = 2, rng_method = FALSE)
  out <- suppressMessages(simulatr_check(study, B = 2))
  expect_named(out, c("results", "evals", "summary"))
  expect_s3_class(out$results, "data.frame")
})

test_that("warning emitted by a method does not abort the run", {
  study <- make_simple_study(B = 2, rng_method = FALSE, warn_in_method = TRUE)
  outputs <- suppressWarnings(simulatr_run(study, B = 2))
  warner_rows <- dplyr::filter(outputs, method == "warner")
  expect_equal(nrow(warner_rows), 2L)
  vals <- vapply(warner_rows$output, function(o) o$value, numeric(1))
  expect_true(all(vals == 1.0))
})
