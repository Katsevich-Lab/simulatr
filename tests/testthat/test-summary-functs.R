test_that("fdp returns correct false-discovery proportion", {
  out <- list(nonnulls = c(1L, 2L, 3L))
  gt <- list(nonnulls = c(1L, 2L))
  # 3 is a false discovery; FDP = 1/3
  expect_equal(fdp(out, gt), 1 / 3)
})

test_that("fdp is 0 when output is empty", {
  expect_equal(fdp(list(nonnulls = integer()), list(nonnulls = 1L)), 0)
})

test_that("power returns correct true-positive rate", {
  out <- list(nonnulls = c(1L, 3L))
  gt <- list(nonnulls = c(1L, 2L, 3L))
  expect_equal(power(out, gt), 2 / 3)
})

test_that("power is 0 when no discoveries", {
  expect_equal(power(list(nonnulls = integer()), list(nonnulls = 1L)), 0)
})
