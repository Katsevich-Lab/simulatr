# Tiny shared fixtures for tests. Kept here (helper-*) so testthat loads
# them automatically before any test file.

make_simple_spec <- function(B = 5, seed = 4L,
                             rng_method = TRUE,
                             warn_in_method = FALSE) {
  # Data generator: small linear-regression design.
  generate_lm_data <- function(beta_0, beta_1, sigma, n) {
    x <- stats::rnorm(n)
    ep <- stats::rnorm(n, sd = sigma)
    y <- beta_0 + beta_1 * x + ep
    data.frame(y = y, x = x)
  }
  data_generator <- simulatr_function(
    f = generate_lm_data,
    arg_names = c("beta_0", "beta_1", "sigma", "n"),
    loop = TRUE
  )

  # Method 1: linear regression fit.
  fit_lm <- function(df) {
    fit <- stats::lm(y ~ x, data = df)
    s <- summary(fit)$coefficients
    row.names(s) <- NULL
    out <- data.frame(
      parameter = c("beta_0", "beta_1"),
      Estimate = s[, "Estimate"],
      p_val = s[, "Pr(>|t|)"]
    )
    out <- tidyr::pivot_longer(out, cols = c("Estimate", "p_val"), names_to = "target")
    out
  }
  lm_method <- simulatr_function(f = fit_lm, packages = "tidyr", loop = TRUE)

  # Method 2: randomized — draws a number that should vary per replicate
  # under the per-replicate-seed protocol.
  random_method <- function(df) {
    data.frame(
      parameter = "rand",
      target = "value",
      value = stats::runif(1)
    )
  }
  random_fn <- simulatr_function(f = random_method, loop = TRUE)

  # Method 3: optional method that emits a benign warning.
  warning_method <- function(df) {
    warning("benign convergence warning")
    data.frame(parameter = "w", target = "value", value = 1.0)
  }
  warning_fn <- simulatr_function(f = warning_method, loop = TRUE)

  run_methods <- list(lm = lm_method)
  if (rng_method) run_methods$rand <- random_fn
  if (warn_in_method) run_methods$warner <- warning_fn

  parameter_grid <- expand.grid(beta_0 = 0, beta_1 = 1)
  # add_ground_truth attaches a list-column; check_simulatr_specifier_object
  # joins on it unconditionally so it has to be present even for specs with
  # no evaluation functions.
  parameter_grid <- add_ground_truth(parameter_grid, function(beta_0, beta_1) {
    list(beta_0 = beta_0, beta_1 = beta_1)
  })
  fixed_parameters <- list(n = 30, sigma = 1, n_processors = 1, seed = seed, B = B)

  simulatr_specifier(
    parameter_grid = parameter_grid,
    fixed_parameters = fixed_parameters,
    generate_data_function = data_generator,
    run_method_functions = run_methods
  )
}
