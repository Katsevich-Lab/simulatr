# Numerical-equivalence checks: the formulas in `metric_*()` constructors
# must agree with the formulas in the legacy `summary_functs.R` compute_*
# helpers (now removed) when applied to the same data.

test_that("fdp and metric_fdp agree with the legacy formula", {
  out <- list(nonnulls = c(1L, 2L, 3L))
  gt  <- list(nonnulls = c(1L, 2L))
  expected <- length(setdiff(out$nonnulls, gt$nonnulls)) /
    max(1, length(out$nonnulls))
  expect_equal(fdp(out, gt), expected, tolerance = 1e-12)
  m <- metric_fdp()
  expect_equal(m@score(out, gt), expected, tolerance = 1e-12)
})

test_that("power matches the legacy formula", {
  out <- list(nonnulls = c(1L, 3L))
  gt  <- list(nonnulls = c(1L, 2L, 3L))
  expected <- length(intersect(out$nonnulls, gt$nonnulls)) /
    max(1, length(gt$nonnulls))
  expect_equal(power(out, gt), expected, tolerance = 1e-12)
  expect_equal(metric_power()@score(out, gt), expected, tolerance = 1e-12)
})

test_that("metric_bias matches legacy compute_bias mean", {
  ests <- c(1.1, 0.9, 1.2, 0.8, 1.0)
  truth <- 1.0
  legacy_bias <- mean(ests) - truth
  m <- metric_bias()
  new_per_rep <- vapply(ests, function(e) {
    m@score(list(estimate = e), list(truth = truth))
  }, numeric(1))
  expect_equal(mean(new_per_rep), legacy_bias, tolerance = 1e-12)
})

test_that("metric_mse matches legacy compute_mse mean", {
  ests <- c(1.1, 0.9, 1.2, 0.8, 1.0)
  truth <- 1.0
  legacy_mse <- mean((ests - truth) ^ 2)
  m <- metric_mse()
  new_per_rep <- vapply(ests, function(e) {
    m@score(list(estimate = e), list(truth = truth))
  }, numeric(1))
  expect_equal(mean(new_per_rep), legacy_mse, tolerance = 1e-12)
})

test_that("metric_coverage matches indicator-based legacy coverage mean", {
  lowers <- c(0.5, 0.6, 1.5, 0.0)
  uppers <- c(1.5, 1.4, 2.0, 0.5)
  truth <- 1.0
  legacy_cov <- mean(lowers < truth & uppers > truth)
  m <- metric_coverage()
  new_per_rep <- vapply(seq_along(lowers), function(i) {
    m@score(list(confint_lower = lowers[[i]], confint_upper = uppers[[i]]),
            list(truth = truth))
  }, numeric(1))
  expect_equal(mean(new_per_rep), legacy_cov, tolerance = 1e-12)
})

test_that("metric_ci_width matches legacy compute_ci_width", {
  lowers <- c(0.5, 0.6, 1.5, 0.0)
  uppers <- c(1.5, 1.4, 2.0, 0.5)
  legacy_widths <- uppers - lowers
  m <- metric_ci_width()
  new_per_rep <- vapply(seq_along(lowers), function(i) {
    m@score(list(confint_lower = lowers[[i]], confint_upper = uppers[[i]]),
            list(truth = 0))
  }, numeric(1))
  expect_equal(new_per_rep, legacy_widths, tolerance = 1e-12)
  expect_equal(mean(new_per_rep), mean(legacy_widths), tolerance = 1e-12)
})

test_that("metric_rejection_probability matches legacy compute_rejection_probability", {
  p_vals <- c(0.001, 0.04, 0.10, 0.5, 0.049)
  legacy <- mean(p_vals < 0.05)
  m <- metric_rejection_probability(threshold = 0.05)
  new_per_rep <- vapply(p_vals, function(p) {
    m@score(list(p_value = p), list(truth = NA))
  }, numeric(1))
  expect_equal(mean(new_per_rep), legacy, tolerance = 1e-12)
})

test_that("metric_count matches legacy compute_count", {
  nonnulls_list <- list(c(1L, 2L), integer(), c(1L, 2L, 3L))
  legacy_counts <- vapply(nonnulls_list, length, integer(1))
  m <- metric_count()
  new_counts <- vapply(nonnulls_list, function(nn) {
    m@score(list(nonnulls = nn), list(nonnulls = NULL))
  }, numeric(1))
  expect_equal(new_counts, as.numeric(legacy_counts), tolerance = 1e-12)
})

test_that("metric_estimate + summarise SD matches legacy compute_se", {
  ests <- c(1.1, 0.9, 1.2, 0.8, 1.0)
  legacy_sd <- stats::sd(ests)
  m <- metric_estimate()
  per_rep <- vapply(ests, function(e) {
    m@score(list(estimate = e), list(truth = 0))
  }, numeric(1))
  # Aggregator's `se` = sd / sqrt(n); recover sd by multiplying.
  n <- length(per_rep)
  agg_se <- stats::sd(per_rep) / sqrt(n)
  recovered_sd <- agg_se * sqrt(n)
  expect_equal(recovered_sd, legacy_sd, tolerance = 1e-12)
})
