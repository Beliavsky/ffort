# Finite degree trigonometry

Run from the repository root:

```sh
python3 tests/degree_trig/test_runner.py
python3 tests/degree_trig/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
```

177 cases cover finite REAL4/8 ACOSD, ASIND, SIND and COSD, ranks zero through
three, assignment/strides, typed empty arrays, keyword X, constant initialization,
KIND non-evaluation, OPTIONAL metadata inquiries, nonreserved scalar/array/result/procedure/
generic names, unsupported types/kinds, domain errors and atomic output rejection.
The runner uses GNU's strict Fortran 2023 mode because these degree intrinsics
are standardized in Fortran 2023. The interpreter itself uses only its existing
Fortran 2018 build requirements.

There are 132 GNU executions, 13 compile-only cases and 32 GNU compile rejections.
All 132 executions now include supported candidate execution comparisons, including
the complete unchanged demo_cosd after bounded T/TL/TR positioning support.
The isolated REAL4 runtime negative-zero SIND case uses an independent exact
signed-zero expectation, not GNU execution agreement; see the oracle receipt.
Runtime/domain failures and legal wider-kind source boundaries are compile-only.

28 precision fixtures contain 204 independently computed values, from 180-digit
mpmath arithmetic on exact represented inputs. Integer-rational degree reduction
precedes transcendental evaluation, with rounding to the requested IEEE result
kind. `generate_precision.py` needs mpmath only for optional regeneration; normal
verification has no mpmath dependency. Expected signed zeros, exact comparisons,
and subnormal distinctions never pass through binary64 comparison or an absolute
tolerance. Explicit precision-case relative tolerances are 5e-7 for REAL4 and
5e-15 for REAL8; ordinary source cases use 3e-7 and 4e-15 where needed.

The complete unchanged upstream demo_acosd and demo_asind programs have exact
output-token agreement with GNU, allowing list-directed spacing differences.
The complete unchanged demo_sind has byte-exact formatted output agreement.
The complete unchanged demo_cosd now has byte-exact formatted output agreement
with GNU after bounded T20 positioning support. Its expectation-only promotion
preserves original source hashes and MIT provenance in upstream.json.

Native tests independently exercise 2,501 parser/adapter/public-IR/runtime/KIND
assertions and 20 direct producer metadata/binding cases. The source harness has
28 adversarial self-tests, including status/stage, output leaks, exact silence,
signed zeros, Decimal precision/subnormal handling and unique registry identities.
A full release native aggregate is the integrator's separate responsibility.
