#' simulatr_study
#'
#' A `simulatr_study` specifies an entire simulation: the parameter grid
#' (with ground truth), fixed parameters, models, methods, and metrics.
#'
#' Construction validates that:
#' - `fixed_parameters` contains `B` and `seed`;
#' - every model's `generate` formal is found in
#'   `colnames(parameter_grid) ∪ names(fixed_parameters) ∪ {"B"}`
#'   (`"B"` allowed only for `batched = TRUE` models);
#' - every method's `run` formals (beyond the first, which is the data
#'   argument) are likewise resolvable;
#' - `models` is a non-empty named list of `simulatr_model` objects,
#'   `methods` is a non-empty named list of `simulatr_method` objects,
#'   and `metrics` (which may be empty) is a named list of
#'   `simulatr_metric` objects.
#'
#' @param parameter_grid Data frame whose rows index problem settings.
#'   May contain a `ground_truth` list column.
#' @param fixed_parameters Named list including at least `B` and `seed`.
#' @param models Named list of [simulatr_model()] objects.
#' @param methods Named list of [simulatr_method()] objects.
#' @param metrics Named list of [simulatr_metric()] objects. May be empty.
#'
#' @return A `simulatr_study` S4 object.
#' @export
simulatr_study <- function(parameter_grid,
                           fixed_parameters,
                           models,
                           methods,
                           metrics = list()) {
  if (inherits(models, "simulatr_model")) models <- list(models)
  if (inherits(methods, "simulatr_method")) methods <- list(methods)
  if (inherits(metrics, "simulatr_metric")) metrics <- list(metrics)
  if (is.null(names(models)) && length(models) > 0L) {
    names(models) <- vapply(models, function(m) m@name, character(1))
  }
  if (is.null(names(methods)) && length(methods) > 0L) {
    names(methods) <- vapply(methods, function(m) m@name, character(1))
  }
  if (is.null(names(metrics)) && length(metrics) > 0L) {
    names(metrics) <- vapply(metrics, function(m) m@name, character(1))
  }
  new(Class = "simulatr_study",
      parameter_grid = parameter_grid,
      fixed_parameters = fixed_parameters,
      models = models,
      methods = methods,
      metrics = metrics)
}

check_validity_simulatr_study <- function(object) {
  fp_names <- names(object@fixed_parameters)
  grid_names <- colnames(object@parameter_grid)
  for (req in c("B", "seed")) {
    if (!(req %in% fp_names) && !(req %in% grid_names)) {
      return(paste0("`", req, "` must be present in `fixed_parameters` or `parameter_grid`."))
    }
  }
  if (length(object@models) == 0L) {
    return("`models` must contain at least one simulatr_model.")
  }
  if (length(object@methods) == 0L) {
    return("`methods` must contain at least one simulatr_method.")
  }
  for (m in object@models) {
    if (!is(m, "simulatr_model")) {
      return("Every entry in `models` must be a simulatr_model.")
    }
  }
  for (m in object@methods) {
    if (!is(m, "simulatr_method")) {
      return("Every entry in `methods` must be a simulatr_method.")
    }
  }
  for (m in object@metrics) {
    if (!is(m, "simulatr_metric")) {
      return("Every entry in `metrics` must be a simulatr_metric.")
    }
  }

  # Cross-check that every model's and method's formals can be resolved
  # against the grid + fixed parameters (+ ground_truth, + B when batched).
  resolvable <- union(grid_names, fp_names)
  for (model_name in names(object@models)) {
    m <- object@models[[model_name]]
    fl <- names(formals(m@generate))
    allowed <- c(resolvable, "ground_truth", if (m@batched) "B")
    unknown <- setdiff(fl, allowed)
    if (length(unknown) > 0L) {
      return(paste0("Model '", model_name, "' has formals not found in ",
                    "parameter_grid, fixed_parameters, or {ground_truth",
                    if (m@batched) ", B", "}: ",
                    paste(unknown, collapse = ", "), "."))
    }
  }
  for (method_name in names(object@methods)) {
    mtd <- object@methods[[method_name]]
    fl <- names(formals(mtd@run))
    # First positional arg is the data realization (or list, if batched).
    rest <- fl[-1L]
    allowed <- c(resolvable, "ground_truth", if (mtd@batched) "B")
    unknown <- setdiff(rest, allowed)
    if (length(unknown) > 0L) {
      return(paste0("Method '", method_name, "' has formals not found in ",
                    "parameter_grid, fixed_parameters, or {ground_truth",
                    if (mtd@batched) ", B", "}: ",
                    paste(unknown, collapse = ", "), "."))
    }
  }
  TRUE
}

setClass("simulatr_study",
         slots = list(parameter_grid = "data.frame",
                      fixed_parameters = "list",
                      models = "list",
                      methods = "list",
                      metrics = "list"),
         validity = check_validity_simulatr_study)
