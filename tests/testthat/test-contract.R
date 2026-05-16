test_that("contract.json ships and parses", {
  p <- contract_path()
  expect_true(file.exists(p))
  txt <- paste(readLines(p, warn = FALSE), collapse = "\n")
  expect_match(txt, "\"schema_version\"")
  expect_match(txt, "\"shard_layout\"")
  expect_match(txt, "\"schemas\"")
})

test_that("contract_version returns a positive integer", {
  v <- contract_version()
  expect_type(v, "integer")
  expect_gte(v, 1L)
})

test_that("contract_hash is a non-empty string", {
  h <- contract_hash()
  expect_type(h, "character")
  expect_true(nzchar(h))
})

test_that("simulatr_session_info embeds contract metadata", {
  info <- simulatr_session_info()
  expect_s3_class(info, "simulatr_session_info")
  expect_equal(info$contract_version, contract_version())
  expect_equal(info$contract_hash, contract_hash())
})
