#' Capture session info plus contract metadata for a result artifact
#'
#' Returns the standard `utils::sessionInfo()` augmented with the
#' simulatr pipeline contract version and the contract file hash. Embed
#' the result into every saved study artifact (e.g., as an attribute or
#' an extra slot in an `.rds`) so two runs can be compared bit-for-bit
#' against the package and pipeline they were produced under.
#'
#' @return A list with class `simulatr_session_info` and elements
#'   `session_info`, `contract_version`, `contract_hash`,
#'   `simulatr_version`, `captured_at`.
#' @export
simulatr_session_info <- function() {
  out <- list(
    session_info     = utils::sessionInfo(),
    simulatr_version = utils::packageVersion("simulatr"),
    contract_version = contract_version(),
    contract_hash    = contract_hash(),
    captured_at      = Sys.time()
  )
  class(out) <- c("simulatr_session_info", "list")
  out
}

#' @export
print.simulatr_session_info <- function(x, ...) {
  cat("simulatr_session_info\n")
  cat("  simulatr version : ", as.character(x$simulatr_version), "\n", sep = "")
  cat("  contract version : ", x$contract_version, "\n", sep = "")
  cat("  contract hash    : ", x$contract_hash, "\n", sep = "")
  cat("  captured at      : ", format(x$captured_at), "\n\n", sep = "")
  print(x$session_info)
  invisible(x)
}
