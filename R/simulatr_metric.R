#' simulatr_metric
#'
#' A `simulatr_metric` bundles an evaluation function with metadata.
#'
#' `score` must accept exactly the arguments `output` and `ground_truth`.
#' This is verified at construction.
#'
#' @param name Character scalar identifying the metric.
#' @param score Function with formals `(output, ground_truth)`. Returns a
#'   numeric scalar.
#' @param settings Named list of metric-level settings. Default `list()`.
#' @param packages Character vector. Default `character(0)`.
#'
#' @return A `simulatr_metric` S4 object.
#' @export
simulatr_metric <- function(name,
                            score,
                            settings = list(),
                            packages = character(0)) {
  new(Class = "simulatr_metric",
      name = name,
      score = score,
      settings = settings,
      packages = packages)
}

setClass("simulatr_metric",
         slots = list(name = "character",
                      score = "function",
                      settings = "list",
                      packages = "character"),
         validity = function(object) {
           if (length(object@name) != 1L || !nzchar(object@name)) {
             return("`name` must be a non-empty character scalar.")
           }
           score_args <- names(formals(object@score))
           required <- c("output", "ground_truth")
           if (!all(required %in% score_args)) {
             missing <- setdiff(required, score_args)
             return(paste0("`score` must accept arguments ",
                           paste(required, collapse = " and "),
                           "; missing: ", paste(missing, collapse = ", "), "."))
           }
           extra <- setdiff(score_args, required)
           if (length(extra) > 0L) {
             return(paste0("`score` accepts unexpected argument(s): ",
                           paste(extra, collapse = ", "),
                           ". Only `output` and `ground_truth` are allowed."))
           }
           TRUE
         })
