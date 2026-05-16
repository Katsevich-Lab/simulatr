#' simulatr_model
#'
#' A `simulatr_model` bundles a data-generating function with metadata.
#'
#' The `generate` function's arguments must be a subset of the union of
#' columns in `parameter_grid`, names of `fixed_parameters`, and the
#' literal `"B"` (allowed only when `batched = TRUE`). This is verified
#' when the model is added to a [simulatr_study()].
#'
#' When `batched = TRUE`, `generate` receives an additional integer `B`
#' and must return a length-`B` list of data realizations. When
#' `batched = FALSE` (default), it returns a single realization.
#'
#' @param name Character scalar identifying the model.
#' @param generate Function producing data from problem parameters.
#' @param settings Named list of model-level settings (rarely used; reserved
#'   for forward compatibility). Default `list()`.
#' @param batched Logical: does `generate` accept `B` and return a list?
#'   Default `FALSE`.
#' @param packages Character vector of packages to load before calling
#'   `generate`. Default `character(0)`.
#'
#' @return A `simulatr_model` S4 object.
#' @export
simulatr_model <- function(name,
                           generate,
                           settings = list(),
                           batched = FALSE,
                           packages = character(0)) {
  new(Class = "simulatr_model",
      name = name,
      generate = generate,
      settings = settings,
      batched = batched,
      packages = packages)
}

setClass("simulatr_model",
         slots = list(name = "character",
                      generate = "function",
                      settings = "list",
                      batched = "logical",
                      packages = "character"),
         validity = function(object) {
           if (length(object@name) != 1L || !nzchar(object@name)) {
             return("`name` must be a non-empty character scalar.")
           }
           if (length(object@batched) != 1L) {
             return("`batched` must be a length-1 logical.")
           }
           TRUE
         })
