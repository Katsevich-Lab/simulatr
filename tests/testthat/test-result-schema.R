# Freezes the result schema described in plan §4.4. Adding or renaming a
# column requires updating the snapshot deliberately.

schema_of <- function(df) {
  data.frame(
    column = colnames(df),
    class = vapply(df, function(x) paste(class(x), collapse = "/"), character(1)),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

test_that("simulatr_check() output schemas are frozen", {
  metric_beta1 <- simulatr_metric(
    name = "beta1_bias",
    score = function(output, ground_truth) output$beta_1 - ground_truth$beta_1
  )
  study <- make_simple_study(B = 2, rng_method = FALSE)
  study@metrics <- list(beta1_bias = metric_beta1)
  out <- suppressMessages(simulatr_check(study, B = 2))
  expect_snapshot(schema_of(out$results))
  expect_snapshot(schema_of(out$evals))
  expect_snapshot(schema_of(out$summary))
})
