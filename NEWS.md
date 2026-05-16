# simulatr (development version)

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
