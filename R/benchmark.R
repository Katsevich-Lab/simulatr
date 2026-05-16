#' Benchmark a single grid row
#'
#' Measures the per-replicate memory allocation and wall-clock time of the
#' three phases (generate, run, evaluate) for one row of `parameter_grid`.
#' Memory numbers come from `bench::mark()`'s `mem_alloc` field — R-heap
#' allocations only — and are decomposed into one row per phase to make
#' the dominant cost obvious.
#'
#' @param study A [simulatr_study()] object.
#' @param row_idx Integer row of `parameter_grid` to benchmark.
#' @param n_warmup Warm-up replicates run before measurement. Default 1.
#' @param n_measure Measured replicates summarised by `max`. Default 3.
#'
#' @return A tibble with one row per phase × method, with columns
#'   `grid_id` (int), `method` (chr), `phase` (chr), `bytes` (dbl),
#'   `seconds` (dbl). Generate is reported once per row (method `NA`).
#' @export
simulatr_benchmark <- function(study, row_idx, n_warmup = 1L, n_measure = 3L) {
  if (!requireNamespace("bench", quietly = TRUE)) {
    stop("simulatr_benchmark() requires the 'bench' package. ",
         "Install it with install.packages('bench').")
  }
  model <- active_model(study)
  load_packages(model@packages)
  seed <- study_seed(study)
  extras_gen <- list(ground_truth = ground_truth_at(study, row_idx))

  bench_once <- function(expr_fn) {
    res <- bench::mark(expr_fn(), iterations = 1L, check = FALSE,
                       filter_gc = FALSE)
    list(bytes = as.numeric(res$mem_alloc[[1]]),
         seconds = as.numeric(res$median[[1]]))
  }

  # Warm up generation.
  for (b in seq_len(n_warmup)) {
    args_gen <- build_call_args(study, row_idx, model@generate, extras_gen)
    R.utils::withSeed(do.call(model@generate, args_gen), seed = seed + b)
  }
  # Measure generation.
  gen_runs <- vector("list", n_measure)
  draw_for_methods <- NULL
  for (b in seq_len(n_measure)) {
    args_gen <- build_call_args(study, row_idx, model@generate, extras_gen)
    gen_runs[[b]] <- bench_once(function() {
      draw_for_methods <<- R.utils::withSeed(do.call(model@generate, args_gen),
                                              seed = seed + n_warmup + b)
    })
  }
  gen_bytes <- max(vapply(gen_runs, `[[`, numeric(1), "bytes"))
  gen_seconds <- max(vapply(gen_runs, `[[`, numeric(1), "seconds"))

  out_rows <- list(
    tibble::tibble(grid_id = as.integer(row_idx),
                   method = NA_character_,
                   phase = "generate",
                   bytes = gen_bytes,
                   seconds = gen_seconds)
  )

  for (mn in names(study@methods)) {
    method <- study@methods[[mn]]
    extras_run <- list(ground_truth = ground_truth_at(study, row_idx))
    args_run <- build_call_args(study, row_idx, method@run,
                                extras_run, skip_first = TRUE)
    last_output <- NULL
    method_runs <- vector("list", n_measure)
    for (b in seq_len(n_measure)) {
      method_runs[[b]] <- bench_once(function() {
        last_output <<- R.utils::withSeed(
          do.call(method@run, c(list(draw_for_methods), args_run)),
          seed = seed + n_warmup + b)
      })
    }
    m_bytes <- max(vapply(method_runs, `[[`, numeric(1), "bytes"))
    m_seconds <- max(vapply(method_runs, `[[`, numeric(1), "seconds"))
    out_rows[[length(out_rows) + 1L]] <- tibble::tibble(
      grid_id = as.integer(row_idx),
      method = mn,
      phase = "run",
      bytes = m_bytes,
      seconds = m_seconds
    )

    if (length(study@metrics) > 0L && !is.null(last_output)) {
      gt <- ground_truth_at(study, row_idx)
      eval_runs <- vector("list", n_measure)
      for (b in seq_len(n_measure)) {
        eval_runs[[b]] <- bench_once(function() {
          for (mt in study@metrics) mt@score(last_output, gt)
        })
      }
      e_bytes <- max(vapply(eval_runs, `[[`, numeric(1), "bytes"))
      e_seconds <- max(vapply(eval_runs, `[[`, numeric(1), "seconds"))
      out_rows[[length(out_rows) + 1L]] <- tibble::tibble(
        grid_id = as.integer(row_idx),
        method = mn,
        phase = "evaluate",
        bytes = e_bytes,
        seconds = e_seconds
      )
    }
  }
  dplyr::bind_rows(out_rows)
}
