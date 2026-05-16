#' Pipeline contract between simulatr and simulatr-pipeline
#'
#' The simulatr R package ships an on-disk contract describing the shard
#' layout, result schemas, and RNG protocol that the Nextflow pipeline
#' (`Katsevich-Lab/simulatr-pipeline`) relies on. The contract file lives at
#' `system.file("extdata", "contract.json", package = "simulatr")` and the
#' pipeline asserts compatibility at workflow start.
#'
#' @return
#'   * `contract_path()` returns the absolute path to the installed
#'     `contract.json`.
#'   * `contract_version()` returns the integer `schema_version` recorded in
#'     that file.
#'   * `contract_hash()` returns the SHA-256 of the file (hex string),
#'     for embedding in result artifacts.
#'
#' @name contract
#' @export
contract_path <- function() {
  p <- system.file("extdata", "contract.json", package = "simulatr")
  if (!nzchar(p)) {
    stop("contract.json is not installed with this build of simulatr.")
  }
  p
}

#' @rdname contract
#' @export
contract_version <- function() {
  raw <- readLines(contract_path(), warn = FALSE)
  m <- regmatches(
    raw,
    regexpr("\"schema_version\"\\s*:\\s*[0-9]+", raw)
  )
  m <- m[nzchar(m)]
  if (length(m) == 0L) {
    stop("contract.json does not declare a schema_version.")
  }
  as.integer(sub(".*:\\s*", "", m[[1L]]))
}

#' @rdname contract
#' @export
contract_hash <- function() {
  bytes <- readBin(contract_path(), what = "raw", n = file.info(contract_path())$size)
  if (requireNamespace("digest", quietly = TRUE)) {
    digest::digest(bytes, algo = "sha256", serialize = FALSE)
  } else {
    paste0("md5:", tools::md5sum(contract_path())[[1L]])
  }
}
