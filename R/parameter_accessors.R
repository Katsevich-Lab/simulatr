#' Get a parameter value from a study
#'
#' Returns the value of a named parameter from a [simulatr_study()]. If the
#' parameter is present in the `parameter_grid`, the value at `row_idx` is
#' returned; if it lives in `fixed_parameters`, the fixed value is returned.
#' If `row_idx` is `NULL` and the parameter is in the grid, the full column
#' is returned.
#'
#' @param study A [simulatr_study()] object.
#' @param row_idx Integer row index of `parameter_grid`, or `NULL`.
#' @param param Character scalar — the parameter name.
#'
#' @return The parameter value.
#' @export
get_param_from_study <- function(study, row_idx, param) {
  param_grid <- study@parameter_grid
  fixed_params <- study@fixed_parameters
  if (param %in% colnames(param_grid)) {
    if (is.null(row_idx)) param_grid[, param] else param_grid[[param]][[row_idx]]
  } else if (param %in% names(fixed_params)) {
    fixed_params[[param]]
  } else {
    stop(paste0("Parameter '", param, "' not present in simulatr_study object."))
  }
}
