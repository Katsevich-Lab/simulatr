utils::globalVariables(c("ground_truth", "output", "value", "method", "metric",
                         "run_id", "grid_id", "phase", "se", "mean_value",
                         "sd", "n", "."))

#' simulatr: A package that powers portable and scalable simulation studies
#'
#' Simulation studies play a crucial role in the development and assessment of
#' statistical methods. `simulatr` separates the specification of a study from
#' its execution and provides four building blocks — [simulatr_model()],
#' [simulatr_method()], [simulatr_metric()] and [simulatr_study()] — together
#' with three verbs — [simulatr_generate()], [simulatr_run()],
#' [simulatr_evaluate()] — and a convenience wrapper [simulatr_check()].
#'
#' @importFrom magrittr %>%
#' @import methods
#'
#' @keywords internal
"_PACKAGE"
