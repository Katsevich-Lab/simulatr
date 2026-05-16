#' simulatr_method
#'
#' A `simulatr_method` bundles a method-application function with metadata.
#'
#' The first argument of `run` is the data realization produced by a
#' [simulatr_model()]'s `generate` function. Any further arguments must
#' be drawn from `parameter_grid ∪ fixed_parameters ∪ {"B"}` (where `"B"`
#' is allowed only when `batched = TRUE`). This is verified when the
#' method is added to a [simulatr_study()].
#'
#' When `batched = TRUE`, the first argument is a length-`B` list and
#' `run` must return a `B`-row tibble with columns `run_id` (int) and
#' `output` (list).
#'
#' @param name Character scalar identifying the method.
#' @param run Function applying the method to data.
#' @param settings Named list of method-level settings. Default `list()`.
#' @param batched Logical. Default `FALSE`.
#' @param packages Character vector. Default `character(0)`.
#'
#' @return A `simulatr_method` S4 object.
#' @export
simulatr_method <- function(name,
                            run,
                            settings = list(),
                            batched = FALSE,
                            packages = character(0)) {
  new(Class = "simulatr_method",
      name = name,
      run = run,
      settings = settings,
      batched = batched,
      packages = packages)
}

setClass("simulatr_method",
         slots = list(name = "character",
                      run = "function",
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
           if (length(formals(object@run)) < 1L) {
             return("`run` must accept at least one argument (the data).")
           }
           TRUE
         })
