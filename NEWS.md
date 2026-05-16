# simulatr 1.0.0

## Phase 3 — Pipeline contract, vignettes, JoSS

* New on-disk **pipeline contract** at
  `inst/extdata/contract.json` documenting the shard layout, result
  schemas (`results`, `evals`, `summary`, `memory`, `timing`,
  `errors`), and RNG protocol shared with `simulatr-pipeline`.
  `contract_path()`, `contract_version()`, and `contract_hash()`
  expose it from R; the pipeline asserts version compatibility at
  workflow start.
* New `simulatr_session_info()` returns `sessionInfo()` augmented
  with the contract version and SHA-256 of `contract.json`. Embed in
  result artifacts to make a run bit-for-bit reproducible.
* Five new vignettes replace the legacy ones:
  *Getting started* (laptop walk-through with `simulatr_check()`),
  *Writing a method* (typed constructors, batched generation, RNG
  protocol), *Running on a cluster* (Nextflow pipeline + Slurm),
  *Reproducibility & seeding* (`simulatr_session_info()`, container,
  `renv.lock`), *Reading your memory profile* (Layer-1 vs Layer-2
  numbers).
* pkgdown site published at <https://katsevich-lab.github.io/simulatr/>;
  `_pkgdown.yml` updated with the five-vignette navbar; new
  `.github/workflows/pkgdown.yaml`.
* New `Dockerfile` + `.github/workflows/docker.yaml` build and push
  `ghcr.io/katsevich-lab/simulatr:<version>` on every release tag;
  `simulatr-pipeline` references the image in its docker profile.
* `R-CMD-check` GitHub Actions workflow now spans
  `{ubuntu-release, ubuntu-devel, macos-release, windows-release}`.
* `paper.md` + `paper.bib` drafted at the repo root for JoSS
  submission. Statement of Need contrasts with `simulator`,
  `SimDesign`, `simhelpers`, `parSim`.
* `Version: 1.0.0` (from `0.0.0.9001`); local `v1.0.0` tag.

# simulatr (development version)

## Phase 2 — Architecture

* **BREAKING:** `simulatr_function` is removed in favor of three typed
  S4 component constructors — `simulatr_model()`, `simulatr_method()`,
  and `simulatr_metric()`. Each validates slot shapes at construction;
  `simulatr_metric()` additionally requires `score`'s formals to be
  exactly `(output, ground_truth)`.
* **BREAKING:** `simulatr_specifier` is replaced by `simulatr_study()`,
  whose `models`/`methods`/`metrics` slots hold named lists of the new
  typed components. Construction cross-checks every component's formals
  against `colnames(parameter_grid) ∪ names(fixed_parameters)` and
  errors with a precise message if any arg is unresolved.
* **BREAKING:** the 197-line `check_simulatr_specifier_object()` monolith
  is split into three public verbs — `simulatr_generate()`,
  `simulatr_run()`, `simulatr_evaluate()` — plus a 30-line
  `simulatr_check()` wrapper. Pipeline-facing helpers `setup_script`,
  `get_ordered_args`, `collate_result_list`, `update_B_sim_spec`,
  `get_params_for_nextflow`, and `get_memory_used` are removed; pipeline
  integration is rewritten in Phase 3.
* `simulatr_run()` defaults to the interleaved generate→run→discard
  loop lifted from `simulatr-pipeline`'s `origin/memory-efficient`
  branch: peak RSS now scales with `1 × data_size` instead of
  `B × data_size`. Pre-computed `draws` may still be supplied.
* New `simulatr_benchmark(study, row_idx, n_warmup, n_measure)` uses
  `bench::mark` (Suggested) to produce decomposed per-replicate memory
  and time numbers (one row per phase × method).
* New `R/builtin_metrics.R` provides `metric_fdp()`, `metric_power()`,
  `metric_bias()`, `metric_mse()`, `metric_estimate()`,
  `metric_coverage()`, `metric_ci_width()`,
  `metric_rejection_probability()`, and `metric_count()` constructors,
  numerically equivalent (1e-12) to the legacy `compute_*` formulas.
  `R/summary_functs.R` is removed.
* The result schema (`results`, `evals`, `summary` tibbles) is frozen
  via `expect_snapshot()` tests.
* RNG protocol invariants — same seed → same draws, different seeds →
  different draws, reordering `parameter_grid` does not perturb a row's
  seed — have explicit tests.

## Phase 1 — Foundation

* License clarification: MIT, with `Katsevich Lab` as the copyright
  holder for the current development line (2026). DESCRIPTION already
  declared `MIT + file LICENSE`; `LICENSE` and `LICENSE.md` are now
  refreshed to match.
* Bug fix: `check_simulatr_specifier_object()` now uses a distinct
  per-replicate seed (`seed + run_id`) when running methods.
  Previously every replicate reused the same seed, so randomized
  methods (bootstraps, glmnet's random folds, etc.) produced
  identical output across all `B` replicates.
* Bug fix: benign warnings emitted by data generators or methods no
  longer abort the run. Warnings are now captured into the per-row
  result list (via `withCallingHandlers`) and printed for visibility;
  only errors abort. Previously, a single convergence warning could
  erase every result for that row.
* Tests: scaffolded `tests/testthat/` (testthat 3rd edition). Smoke
  tests for each exported function plus regression tests for the seed
  and warning bugs.
* CI: added GitHub Actions workflows for `R CMD check` (ubuntu /
  R-release) and `covr::codecov` coverage. README carries the
  matching badges.
* `CONTRIBUTING.md` added at the repo root.

# simulatr 0.0.0.9001

* Added vignettes "simulatr on a laptop" and "simulatr on a cluster or cloud."
* Added functionality to evaluate performance metrics for each method.
