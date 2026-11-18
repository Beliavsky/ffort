# Derived actual metadata in fixed CHARACTER expressions

Independent source-only regression draft. All 12 fixtures compile and execute under GNU with exact formatted output. The byte-preserved historical `three_features.f90` prints `>03>06:0614` followed by one newline; provenance pins its source hash. Eight cases also pass certified 0.47. Four same-path positive expectations already fail on 0.47: bound nested constructors, bound zero-trip LEN, and two LEN/zero-trip no-execution cases. Their first outcomes are retained, not presented as newly introduced regressions.

Synthetic tests cover fixed CHARACTER type-bound and ordinary functions, derived variable/structure/default constructor/result/recursive-result actuals, numeric component actuals and constant-length inquiry that must not execute an ERROR STOP function. All success stderr and CHECK stdout are empty and formatted records exact. No production or historical fixture was edited. No candidate run is claimed yet.

`test_fixed_character_derived_guards.f90` is a source-only native draft, not compiled. It uses public parsed IR and independently mutates derived type/symbol/rank/extent/dimensions, component selectors and cycles, default argument metadata, and derived-result procedure references/argument cycles. Parent owns final direct linking and diagnostic verification.

```
python3 generate_cases.py
python3 run_tests.py --candidate /path/to/cli --gfortran /path/to/gfortran --result results.json
python3 self_test.py
```
