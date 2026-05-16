# simulatr_check() output schemas are frozen

    Code
      schema_of(out$results)
    Output
          column     class
      1  grid_id   integer
      2   method character
      3 chunk_id   integer
      4   run_id   integer
      5   output      list

---

    Code
      schema_of(out$evals)
    Output
         column     class
      1 grid_id   integer
      2  method character
      3  metric character
      4  run_id   integer
      5   value   numeric

---

    Code
      schema_of(out$summary)
    Output
         column     class
      1 grid_id   integer
      2  method character
      3  metric character
      4    mean   numeric
      5      se   numeric
      6       n   integer

