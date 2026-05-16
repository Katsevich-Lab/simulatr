# RNG invariants from plan §4.5.

test_that("identical seed produces identical draws across two runs", {
  s1 <- make_simple_study(B = 4, seed = 42L, rng_method = TRUE)
  s2 <- make_simple_study(B = 4, seed = 42L, rng_method = TRUE)
  o1 <- simulatr_run(s1, B = 4)
  o2 <- simulatr_run(s2, B = 4)
  v1 <- vapply(dplyr::filter(o1, method == "rand")$output, function(o) o$rand, numeric(1))
  v2 <- vapply(dplyr::filter(o2, method == "rand")$output, function(o) o$rand, numeric(1))
  expect_equal(v1, v2)
})

test_that("different seeds produce different draws", {
  s1 <- make_simple_study(B = 4, seed = 42L, rng_method = TRUE)
  s2 <- make_simple_study(B = 4, seed = 100L, rng_method = TRUE)
  o1 <- simulatr_run(s1, B = 4)
  o2 <- simulatr_run(s2, B = 4)
  v1 <- vapply(dplyr::filter(o1, method == "rand")$output, function(o) o$rand, numeric(1))
  v2 <- vapply(dplyr::filter(o2, method == "rand")$output, function(o) o$rand, numeric(1))
  expect_false(isTRUE(all.equal(v1, v2)))
})

test_that("reordering parameter_grid does not perturb a row's seed", {
  # Build a 2-row grid; record outputs at each row. Reorder; record again.
  # The output at the original row 2 should still equal its value before the swap.
  generate_lm_data <- function(beta_0, beta_1, sigma, n) {
    x <- stats::rnorm(n)
    ep <- stats::rnorm(n, sd = sigma)
    y <- beta_0 + beta_1 * x + ep
    data.frame(y = y, x = x)
  }
  model <- simulatr_model(name = "lm_data", generate = generate_lm_data)
  rand_method <- simulatr_method(name = "rand", run = function(df) list(rand = stats::runif(1)))
  pg <- expand.grid(beta_0 = c(0, 1), beta_1 = c(1, 2))
  pg <- add_ground_truth(pg, function(beta_0, beta_1) list(beta_0 = beta_0, beta_1 = beta_1))
  fp <- list(n = 10, sigma = 1, seed = 7L, B = 3L)

  study_a <- simulatr_study(
    parameter_grid = pg,
    fixed_parameters = fp,
    models = list(lm_data = model),
    methods = list(rand = rand_method)
  )
  out_a <- simulatr_run(study_a, B = 3)
  vals_per_row_a <- split(
    vapply(out_a$output, function(o) o$rand, numeric(1)),
    out_a$grid_id
  )

  reorder_idx <- c(4L, 3L, 2L, 1L)
  pg2 <- pg[reorder_idx, , drop = FALSE]
  rownames(pg2) <- NULL
  study_b <- simulatr_study(
    parameter_grid = pg2,
    fixed_parameters = fp,
    models = list(lm_data = model),
    methods = list(rand = rand_method)
  )
  out_b <- simulatr_run(study_b, B = 3)
  vals_per_row_b <- split(
    vapply(out_b$output, function(o) o$rand, numeric(1)),
    out_b$grid_id
  )

  # The replicates at grid_id=1 of study_b correspond to the parameter row
  # that lived at position 4 of study_a — and the seeds are determined
  # solely by (seed, run_id), so the random draws should match in value.
  # Since this test's method ignores the parameter values (just calls
  # runif), the rand outputs depend only on the seed schedule. Therefore
  # all rows should produce identical random sequences.
  expect_equal(vals_per_row_a[[1]], vals_per_row_b[[1]])
  expect_equal(vals_per_row_a[[2]], vals_per_row_b[[1]])
  expect_equal(vals_per_row_a[[3]], vals_per_row_b[[1]])
})
