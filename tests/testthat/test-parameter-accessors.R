test_that("get_param_from_study resolves from grid and fixed params", {
  study <- make_simple_study(B = 2, rng_method = FALSE)
  expect_equal(get_param_from_study(study, 1, "beta_0"), 0)
  expect_equal(get_param_from_study(study, 1, "n"), 30)
  expect_equal(get_param_from_study(study, NULL, "B"), 2)
  expect_error(get_param_from_study(study, 1, "nope"))
})
