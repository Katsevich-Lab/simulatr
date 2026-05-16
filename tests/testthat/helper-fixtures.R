# Tiny shared fixtures for tests. Kept here (helper-*) so testthat loads
# them automatically before any test file.

make_simple_study <- function(B = 5L, seed = 4L,
                              rng_method = TRUE,
                              warn_in_method = FALSE) {
  generate_lm_data <- function(beta_0, beta_1, sigma, n) {
    x <- stats::rnorm(n)
    ep <- stats::rnorm(n, sd = sigma)
    y <- beta_0 + beta_1 * x + ep
    data.frame(y = y, x = x)
  }
  model <- simulatr_model(
    name = "lm_data",
    generate = generate_lm_data
  )

  fit_lm <- function(df) {
    fit <- stats::lm(y ~ x, data = df)
    s <- summary(fit)$coefficients
    list(beta_0 = unname(s["(Intercept)", "Estimate"]),
         beta_1 = unname(s["x", "Estimate"]))
  }
  lm_method <- simulatr_method(name = "lm", run = fit_lm)

  random_method <- function(df) {
    list(rand = stats::runif(1))
  }
  rand_method <- simulatr_method(name = "rand", run = random_method)

  warning_method <- function(df) {
    warning("benign convergence warning")
    list(value = 1.0)
  }
  warner_method <- simulatr_method(name = "warner", run = warning_method)

  methods <- list(lm = lm_method)
  if (rng_method) methods$rand <- rand_method
  if (warn_in_method) methods$warner <- warner_method

  parameter_grid <- expand.grid(beta_0 = 0, beta_1 = 1)
  parameter_grid <- add_ground_truth(parameter_grid, function(beta_0, beta_1) {
    list(beta_0 = beta_0, beta_1 = beta_1, truth = beta_1)
  })
  fixed_parameters <- list(n = 30, sigma = 1, seed = seed, B = B)

  simulatr_study(
    parameter_grid = parameter_grid,
    fixed_parameters = fixed_parameters,
    models = list(lm_data = model),
    methods = methods
  )
}
