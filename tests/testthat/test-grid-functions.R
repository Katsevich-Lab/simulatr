test_that("create_param_grid_fractional_factorial yields the expected shape", {
  varying_values <- list(x = seq(-2, 2, 1), y = seq(0, 2, 1))
  baseline_values <- list(x = 0, y = 1)
  grid <- create_param_grid_fractional_factorial(varying_values, baseline_values)
  expect_s3_class(grid, "data.frame")
  expect_true(all(c("x", "y", "grid_id", "arm_x", "arm_y") %in% colnames(grid)))
  # Each varying value contributes one row, with the shared baseline (0, 1)
  # deduplicated across the two arms: 5 + 3 - 1 = 7.
  expect_equal(nrow(grid), 7L)
  # grid_id is a contiguous 1..n sequence.
  expect_equal(grid$grid_id, seq_len(nrow(grid)))
})

test_that("create_param_grid_two_way_factorial has correct row count and arm indicator", {
  param_vals <- list(g = seq(1, 6, 1), pi = c(0.1, 0.2, 0.3))
  arm_names <- c("pi_small", "pi_intermediate", "pi_big")
  grid <- create_param_grid_two_way_factorial(param_vals, arm_names, "pi")
  expect_equal(nrow(grid), length(param_vals$g) * length(param_vals$pi))
  expect_true(all(paste0("arm_", arm_names) %in% colnames(grid)))
})

test_that("add_ground_truth attaches a list column", {
  pg <- data.frame(a = 1:3, b = 4:6)
  gt_fn <- function(a, b) a + b
  out <- add_ground_truth(pg, gt_fn)
  expect_true("ground_truth" %in% colnames(out))
  expect_equal(out$ground_truth, list(5, 7, 9))
})
