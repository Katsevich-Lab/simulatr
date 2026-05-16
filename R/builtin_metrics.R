#' False discovery proportion of a discovery set
#'
#' @param output A method output with a `nonnulls` integer vector field.
#' @param ground_truth A ground-truth list with a `nonnulls` integer vector.
#'
#' @return The proportion of `output$nonnulls` that are not in
#'   `ground_truth$nonnulls`. Zero when `output$nonnulls` is empty.
#' @export
fdp <- function(output, ground_truth) {
  length(setdiff(output$nonnulls, ground_truth$nonnulls)) /
    max(1, length(output$nonnulls))
}

#' Power of a discovery set
#'
#' @inheritParams fdp
#'
#' @return The proportion of `ground_truth$nonnulls` that appear in
#'   `output$nonnulls`. Zero when `ground_truth$nonnulls` is empty.
#' @export
power <- function(output, ground_truth) {
  length(intersect(output$nonnulls, ground_truth$nonnulls)) /
    max(1, length(ground_truth$nonnulls))
}

#' Family-wise error indicator
#'
#' @inheritParams fdp
#' @param k False-discovery tolerance threshold.
#'
#' @return `TRUE` when the number of false discoveries is at least `k`.
#' @export
fwe <- function(output, ground_truth, k = 1) {
  length(setdiff(output$nonnulls, ground_truth$nonnulls)) >= k
}

#' Built-in metric constructors
#'
#' Each function returns a [simulatr_metric()] object whose `score` is a
#' per-replicate evaluation. Aggregate quantities (mean ± Monte Carlo SE)
#' come from [simulatr_evals_summarise()].
#'
#' These replace the `compute_*` family that used to live in
#' `R/summary_functs.R`. The formulas are unchanged; only the calling
#' convention is new.
#'
#' Conventions for `output` and `ground_truth`:
#' - Discovery-set metrics expect `output$nonnulls` and `ground_truth$nonnulls`.
#' - Point-estimation metrics expect `output$estimate` (numeric) and
#'   `ground_truth$truth` (numeric).
#' - Confidence-interval metrics expect `output$confint_lower`,
#'   `output$confint_upper`, and `ground_truth$truth`.
#' - Testing metrics expect `output$p_value` (numeric).
#'
#' @name builtin_metrics
NULL

#' @rdname builtin_metrics
#' @export
metric_fdp <- function() {
  simulatr_metric(name = "fdp", score = function(output, ground_truth) fdp(output, ground_truth))
}

#' @rdname builtin_metrics
#' @export
metric_power <- function() {
  simulatr_metric(name = "power", score = function(output, ground_truth) power(output, ground_truth))
}

#' @rdname builtin_metrics
#' @export
metric_bias <- function() {
  simulatr_metric(name = "bias", score = function(output, ground_truth) {
    output$estimate - ground_truth$truth
  })
}

#' @rdname builtin_metrics
#' @export
metric_mse <- function() {
  simulatr_metric(name = "mse", score = function(output, ground_truth) {
    (output$estimate - ground_truth$truth) ^ 2
  })
}

#' @rdname builtin_metrics
#' @details `metric_estimate()` is a per-replicate metric returning the raw
#'   estimate. Combine with [simulatr_evals_summarise()] to obtain the Monte
#'   Carlo standard error (`se`) and the sample standard deviation
#'   (`se * sqrt(n)`).
#' @export
metric_estimate <- function() {
  simulatr_metric(name = "estimate", score = function(output, ground_truth) {
    as.numeric(output$estimate)
  })
}

#' @rdname builtin_metrics
#' @export
metric_coverage <- function() {
  simulatr_metric(name = "coverage", score = function(output, ground_truth) {
    as.numeric(output$confint_lower < ground_truth$truth &
                 output$confint_upper > ground_truth$truth)
  })
}

#' @rdname builtin_metrics
#' @export
metric_ci_width <- function() {
  simulatr_metric(name = "ci_width", score = function(output, ground_truth) {
    output$confint_upper - output$confint_lower
  })
}

#' @rdname builtin_metrics
#' @param threshold P-value threshold for rejection. Default 0.05.
#' @export
metric_rejection_probability <- function(threshold = 0.05) {
  force(threshold)
  simulatr_metric(
    name = "rejection_probability",
    settings = list(threshold = threshold),
    score = function(output, ground_truth) {
      as.numeric(output$p_value < threshold)
    }
  )
}

#' @rdname builtin_metrics
#' @export
metric_count <- function() {
  simulatr_metric(name = "count", score = function(output, ground_truth) {
    length(output$nonnulls)
  })
}
