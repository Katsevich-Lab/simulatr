test_that("simulatr_benchmark returns a frozen-schema tibble", {
  skip_if_not_installed("bench")
  study <- make_simple_study(B = 2, rng_method = FALSE)
  bench <- simulatr_benchmark(study, row_idx = 1L,
                              n_warmup = 1L, n_measure = 1L)
  expect_named(bench, c("grid_id", "method", "phase", "bytes", "seconds"))
  expect_true(all(c("generate", "run") %in% bench$phase))
  expect_true(is.integer(bench$grid_id))
  expect_true(all(bench$bytes >= 0))
  expect_true(all(bench$seconds >= 0))
})
