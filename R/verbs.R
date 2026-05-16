#' Generate, run, and evaluate a simulatr study
#'
#' Three verbs realize a [simulatr_study()]:
#' - [simulatr_generate()] produces data draws for every grid row × replicate.
#' - [simulatr_run()] applies each method to every draw.
#' - [simulatr_evaluate()] applies each metric to every method output.
#'
#' `simulatr_check()` is a thin wrapper that pipelines all three with a small
#' `B` for laptop debugging.
#'
#' Each replicate's RNG seed is `study@fixed_parameters$seed + run_id`. The
#' same seed is used for generation and method application within a
#' replicate, so reordering rows of `parameter_grid` does not change the
#' draws or outputs for any replicate.
#'
#' @name simulatr-verbs
NULL

# --- internal helpers -------------------------------------------------------

# Build a named-arg list for `fn` by pulling each formal from the study,
# optionally overriding with `extras`. The first positional arg may be
# omitted (used for method@run, whose first arg is the data).
build_call_args <- function(study, row_idx, fn, extras = list(), skip_first = FALSE) {
  arg_names <- names(formals(fn))
  if (skip_first) arg_names <- arg_names[-1L]
  out <- vector("list", length(arg_names))
  names(out) <- arg_names
  for (a in arg_names) {
    if (a %in% names(extras)) {
      out[[a]] <- extras[[a]]
    } else {
      out[[a]] <- get_param_from_study(study, row_idx, a)
    }
  }
  out
}

load_packages <- function(pkgs) {
  if (length(pkgs) == 0L) return(invisible())
  for (p in pkgs) {
    if (!is.na(p) && nzchar(p)) {
      requireNamespace(p, quietly = TRUE)
    }
  }
}

resolve_B <- function(study, B) {
  if (is.null(B)) get_param_from_study(study, NULL, "B") else B
}

study_seed <- function(study) {
  get_param_from_study(study, NULL, "seed")
}

active_model <- function(study) {
  if (length(study@models) > 1L) {
    warning("simulatr Phase 2 uses only the first model in `models`.", call. = FALSE)
  }
  study@models[[1L]]
}

ground_truth_at <- function(study, row_idx) {
  if ("ground_truth" %in% colnames(study@parameter_grid)) {
    study@parameter_grid[["ground_truth"]][[row_idx]]
  } else {
    NULL
  }
}

# --- simulatr_generate -----------------------------------------------------

#' @rdname simulatr-verbs
#'
#' @param study A [simulatr_study()] object.
#' @param B Number of replicates per grid row. Defaults to the study's `B`.
#'
#' @return [simulatr_generate()] returns a tibble with columns
#'   `grid_id` (int), `run_id` (int), `chunk_id` (int), `draws` (list).
#' @export
simulatr_generate <- function(study, B = NULL) {
  B <- resolve_B(study, B)
  model <- active_model(study)
  load_packages(model@packages)
  seed <- study_seed(study)
  n_rows <- nrow(study@parameter_grid)
  out_pieces <- vector("list", n_rows)
  for (row_idx in seq_len(n_rows)) {
    extras_base <- list(ground_truth = ground_truth_at(study, row_idx))
    if (model@batched) {
      extras_base$B <- B
      args <- build_call_args(study, row_idx, model@generate, extras_base)
      draws_list <- R.utils::withSeed(do.call(model@generate, args), seed = seed + 1L)
      if (length(draws_list) != B) {
        stop("Batched model returned ", length(draws_list), " draws; expected ", B, ".")
      }
    } else {
      draws_list <- vector("list", B)
      for (b in seq_len(B)) {
        args <- build_call_args(study, row_idx, model@generate, extras_base)
        draws_list[[b]] <- R.utils::withSeed(do.call(model@generate, args),
                                             seed = seed + b)
      }
    }
    out_pieces[[row_idx]] <- tibble::tibble(
      grid_id = as.integer(row_idx),
      run_id = as.integer(seq_len(B)),
      chunk_id = 1L,
      draws = draws_list
    )
  }
  dplyr::bind_rows(out_pieces)
}

# --- simulatr_run ----------------------------------------------------------

#' @rdname simulatr-verbs
#'
#' @param draws Optional tibble produced by [simulatr_generate()]. When
#'   `NULL` (the default), [simulatr_run()] runs the memory-efficient
#'   interleaved generate→run→discard loop: a single replicate is drawn,
#'   passed to every method, and discarded before the next replicate is
#'   drawn. Peak RSS scales with `1 × data_size` rather than `B × data_size`.
#' @export
simulatr_run <- function(study, B = NULL, draws = NULL) {
  B <- resolve_B(study, B)
  seed <- study_seed(study)
  n_rows <- nrow(study@parameter_grid)
  method_names <- names(study@methods)
  for (m in study@methods) load_packages(m@packages)
  if (!is.null(draws)) {
    return(run_from_draws(study, draws))
  }
  model <- active_model(study)
  load_packages(model@packages)
  for (mn in method_names) {
    if (study@methods[[mn]]@batched) {
      stop("Batched methods are not yet implemented in Phase 2. ",
           "Method '", mn, "' has batched = TRUE.")
    }
  }
  if (model@batched) {
    # Batched generation: fall back to generate-then-run; per-rep
    # interleaving is incompatible with a single batched draw call.
    draws <- simulatr_generate(study, B = B)
    return(run_from_draws(study, draws))
  }

  out_pieces <- vector("list", n_rows * length(method_names))
  k <- 0L
  for (row_idx in seq_len(n_rows)) {
    extras_gen <- list(ground_truth = ground_truth_at(study, row_idx))
    method_buf <- lapply(method_names, function(mn) vector("list", B))
    names(method_buf) <- method_names
    for (b in seq_len(B)) {
      args_gen <- build_call_args(study, row_idx, model@generate, extras_gen)
      draw <- R.utils::withSeed(do.call(model@generate, args_gen),
                                 seed = seed + b)
      for (mn in method_names) {
        method <- study@methods[[mn]]
        extras_run <- list(ground_truth = ground_truth_at(study, row_idx))
        args_run <- build_call_args(study, row_idx, method@run,
                                    extras_run, skip_first = TRUE)
        full_args <- c(list(draw), args_run)
        out <- R.utils::withSeed(do.call(method@run, full_args),
                                 seed = seed + b)
        method_buf[[mn]][[b]] <- out
      }
      rm(draw)
    }
    for (mn in method_names) {
      k <- k + 1L
      out_pieces[[k]] <- tibble::tibble(
        grid_id = as.integer(row_idx),
        method = mn,
        chunk_id = 1L,
        run_id = as.integer(seq_len(B)),
        output = method_buf[[mn]]
      )
    }
  }
  dplyr::bind_rows(out_pieces)
}

run_from_draws <- function(study, draws) {
  method_names <- names(study@methods)
  seed <- study_seed(study)
  out_pieces <- vector("list", nrow(draws) * length(method_names))
  k <- 0L
  for (i in seq_len(nrow(draws))) {
    row_idx <- draws$grid_id[[i]]
    run_id <- draws$run_id[[i]]
    draw <- draws$draws[[i]]
    for (mn in method_names) {
      method <- study@methods[[mn]]
      extras_run <- list(ground_truth = ground_truth_at(study, row_idx))
      args_run <- build_call_args(study, row_idx, method@run,
                                  extras_run, skip_first = TRUE)
      full_args <- c(list(draw), args_run)
      out <- R.utils::withSeed(do.call(method@run, full_args),
                               seed = seed + run_id)
      k <- k + 1L
      out_pieces[[k]] <- tibble::tibble(
        grid_id = as.integer(row_idx),
        method = mn,
        chunk_id = 1L,
        run_id = as.integer(run_id),
        output = list(out)
      )
    }
  }
  dplyr::bind_rows(out_pieces)
}

# --- simulatr_evaluate -----------------------------------------------------

#' @rdname simulatr-verbs
#'
#' @param outputs A tibble of method outputs as returned by [simulatr_run()].
#'
#' @return [simulatr_evaluate()] returns a tibble with columns
#'   `grid_id` (int), `method` (chr), `metric` (chr), `run_id` (int),
#'   `value` (dbl).
#' @export
simulatr_evaluate <- function(study, outputs) {
  if (length(study@metrics) == 0L) {
    return(tibble::tibble(
      grid_id = integer(0),
      method = character(0),
      metric = character(0),
      run_id = integer(0),
      value = numeric(0)
    ))
  }
  outputs_with_gt <- outputs
  outputs_with_gt$ground_truth <- lapply(outputs_with_gt$grid_id, function(g) {
    ground_truth_at(study, g)
  })
  purrr::map_dfr(study@metrics, function(m) {
    values <- purrr::map2_dbl(outputs_with_gt$output,
                              outputs_with_gt$ground_truth,
                              m@score)
    tibble::tibble(
      grid_id = as.integer(outputs_with_gt$grid_id),
      method = as.character(outputs_with_gt$method),
      metric = m@name,
      run_id = as.integer(outputs_with_gt$run_id),
      value = as.numeric(values)
    )
  })
}

#' Summarise evaluations
#'
#' Collapse the long per-replicate `evals` tibble into one mean ± Monte Carlo
#' standard error row per (grid_id, method, metric).
#'
#' @param evals A tibble as returned by [simulatr_evaluate()].
#'
#' @return A tibble with columns `grid_id` (int), `method` (chr),
#'   `metric` (chr), `mean` (dbl), `se` (dbl), `n` (int).
#' @export
simulatr_evals_summarise <- function(evals) {
  if (nrow(evals) == 0L) {
    return(tibble::tibble(
      grid_id = integer(0),
      method = character(0),
      metric = character(0),
      mean = numeric(0),
      se = numeric(0),
      n = integer(0)
    ))
  }
  evals %>%
    dplyr::group_by(grid_id, method, metric) %>%
    dplyr::summarise(
      mean = mean(value, na.rm = TRUE),
      se = stats::sd(value, na.rm = TRUE) / sqrt(sum(!is.na(value))),
      n = sum(!is.na(value)),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      grid_id = as.integer(grid_id),
      method = as.character(method),
      metric = as.character(metric),
      n = as.integer(n)
    )
}

# --- simulatr_check --------------------------------------------------------

#' @rdname simulatr-verbs
#'
#' @return `simulatr_check()` returns a list `list(results = ..., evals = ...,
#'   summary = ...)`, where `results` is the outputs tibble.
#' @export
simulatr_check <- function(study, B = 2) {
  message("Generating ", B, " replicates per grid row and applying methods...")
  results <- simulatr_run(study, B = B)
  message("Evaluating ", length(study@metrics), " metric(s)...")
  evals <- simulatr_evaluate(study, results)
  summary <- simulatr_evals_summarise(evals)
  message("simulatr_check complete.")
  list(results = results, evals = evals, summary = summary)
}
