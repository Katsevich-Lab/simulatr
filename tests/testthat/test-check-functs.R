test_that("check_simulatr_specifier_object runs and returns expected shape", {
  spec <- make_simple_spec(B = 3, rng_method = FALSE)
  out <- check_simulatr_specifier_object(spec, B_in = 3, parallel = FALSE)
  expect_named(out, c("results", "metrics", "data_generation_times",
                      "data_generation_bytes", "method_times", "method_bytes"))
  expect_s3_class(out$results, "data.frame")
  expect_true(nrow(out$results) > 0)
  expect_true("method" %in% colnames(out$results))
  expect_true("run_id" %in% colnames(out$results))
})

test_that("regression: randomized methods produce different output across replicates", {
  # Before the seed fix, every replicate of a randomized method reused
  # the same `seed`, so output was identical across reps. After the fix,
  # per-replicate seeds (`seed + run_id`) ensure variation.
  spec <- make_simple_spec(B = 5, rng_method = TRUE)
  out <- check_simulatr_specifier_object(spec, B_in = 5, parallel = FALSE)
  rand_rows <- dplyr::filter(out$results, method == "rand")
  values <- vapply(rand_rows$output, function(o) o$value[[1]], numeric(1))
  expect_length(unique(values), 5L)
})

test_that("regression: benign warning in a method is captured, not fatal", {
  # Before the fix, tryCatch(warning = ...) aborted on the first warning
  # and lost every result row. Now warnings are captured into the return
  # value via withCallingHandlers and only errors abort.
  spec <- make_simple_spec(B = 3, rng_method = FALSE, warn_in_method = TRUE)
  out <- check_simulatr_specifier_object(spec, B_in = 3, parallel = FALSE)
  # Output should still contain the warner's value for each replicate.
  warner_rows <- dplyr::filter(out$results, method == "warner")
  expect_equal(nrow(warner_rows), 3L)
  vals <- vapply(warner_rows$output, function(o) o$value[[1]], numeric(1))
  expect_true(all(vals == 1.0))
})

test_that("RNG protocol: identical seed produces identical results", {
  spec_a <- make_simple_spec(B = 4, seed = 42L, rng_method = TRUE)
  spec_b <- make_simple_spec(B = 4, seed = 42L, rng_method = TRUE)
  out_a <- check_simulatr_specifier_object(spec_a, B_in = 4, parallel = FALSE)
  out_b <- check_simulatr_specifier_object(spec_b, B_in = 4, parallel = FALSE)
  vals_a <- vapply(dplyr::filter(out_a$results, method == "rand")$output,
                   function(o) o$value[[1]], numeric(1))
  vals_b <- vapply(dplyr::filter(out_b$results, method == "rand")$output,
                   function(o) o$value[[1]], numeric(1))
  expect_equal(vals_a, vals_b)
})

test_that("RNG protocol: different seed produces different results", {
  spec_a <- make_simple_spec(B = 4, seed = 42L, rng_method = TRUE)
  spec_b <- make_simple_spec(B = 4, seed = 100L, rng_method = TRUE)
  out_a <- check_simulatr_specifier_object(spec_a, B_in = 4, parallel = FALSE)
  out_b <- check_simulatr_specifier_object(spec_b, B_in = 4, parallel = FALSE)
  vals_a <- vapply(dplyr::filter(out_a$results, method == "rand")$output,
                   function(o) o$value[[1]], numeric(1))
  vals_b <- vapply(dplyr::filter(out_b$results, method == "rand")$output,
                   function(o) o$value[[1]], numeric(1))
  expect_false(isTRUE(all.equal(vals_a, vals_b)))
})

test_that("get_memory_used returns a positive number", {
  expect_gt(get_memory_used(), 0)
})
