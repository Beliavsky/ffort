# Bounded ISNAN GNU extension

`ISNAN(X)` is a **GNU Fortran extension**, not a Fortran2018 intrinsic. See the
[GNU ISNAN specification](https://gcc.gnu.org/onlinedocs/gcc-15.2.0/gfortran/ISNAN.html).
This prototype accepts one REAL(4/8) scalar or rank-one/two/three argument, supplied
positionally or as `X=`, and returns default LOGICAL(4) with the same shape.
Supported sections, constructors, array-valued calls and row-gather expressions
compose through the existing elemental evaluation machinery. Constant finite
expressions, empty arrays and masked WHERE/FORALL evaluation are covered.

The extension is explicitly enabled in GNU oracle commands with
`-std=f2018 -pedantic-errors -fall-intrinsics`. A separate strict-standard probe
without `-fall-intrinsics` must reject the otherwise same fixture. Acceptance by
the prototype is not presented as standard-conforming Fortran2018 support.

## Finite-value policy is unchanged

The interpreter continues to reject NaN and Infinity values. Invalid operations
such as SQRT of a negative value, division by zero and overflowing EXP fail before
ISNAN can consume their result. Native forged NaN/Infinity values also fail.
Consequently ISNAN returns false for every supported finite input, including
signed zero, extreme finite values and supported subnormals. It does **not**
silently classify a forbidden NaN as false. General IEEE exceptional-value
handling, IEEE_VALUE construction and the NaN-return path of user routines are
outside this milestone.

KIND(ISNAN(X)) remains unevaluated and can inquire about undefined or unallocated
X. It still validates intrinsic metadata. Empty enclosing expressions and masked
execution retain the same distinction between metadata validation and data
reads. Runtime validation requires one argument, LOGICAL(4) result, matching
operand shape, REAL(4/8) operand and no optional-slot mask; malformed direct IR
cannot bypass this through KIND or a zero-sized enclosing expression.

Declarations keep precedence over the intrinsic. A data object, user function or
generic named ISNAN is still resolved as that declaration. The independent
adapter checks the source binding before accepting an intrinsic call, so a
same-result-type user call cannot be forged into a built-in ISNAN call. Vendor
patch0062 registers the GNU extension and supplies independent logical elemental
result type, kind and rank metadata; no producer checks are disabled.

## Original quick_sort evidence

Eight new fixtures retain the **entire exact CRLF body** of `quick_sort`, including
its original nested `quick_sort_1` and `interchange_sort`, from supplied
`xutilities.f90` lines8870–8942. Only module/DP-parameter and driver scaffolding
is synthetic. There is no synthetic ISNAN helper, interface or replacement.
`tests/isnan_intrinsic/provenance.json` records source/body hashes, and the runner
checks all eight copies before executing tests.

Drivers cover mixed values, singleton and empty arrays, ordered/reverse inputs,
duplicates, signed values and a47-element partition/recursive case. GNU and the
candidate execute the same source, compare sorted values and permutation arrays,
and check permutation integrity and ordering. This proves finite-input execution
of the original routine, not its NaN early-return path. Older historical fixtures
with a synthetic helper remain unchanged and retain their original provenance.
The full original utility module still meets the separate unchanged array cap.

## Reproduction

    python3 tests/isnan_intrinsic/test_runner.py
    python3 tests/isnan_intrinsic/check_provenance.py
    python3 tests/isnan_intrinsic/run_tests.py --candidate /absolute/path/to/fortfront-interpreter

The runner requires a clean silent successful `--check`, exact text and INTEGER
comparisons, finite REAL comparisons, expected GNU compile stages and explicitly
labeled runtime safety probes. Dangerous/nonfinite-producing probes are compiled,
not executed, under GNU. Source hashes prevent fixture substitution. Native
programs separately exercise producer metadata, adapter and runtime mutations,
source binding, empty/KIND paths, and forged nonfinite values. Native tests use
the official fpm debug profile; GNU execution uses `-fcheck=all` and FPE traps.
