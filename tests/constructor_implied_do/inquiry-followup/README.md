# Constructor inquiry, initializer and nested-control followups

These 22 fixtures extend the independent suite without rewriting its original
95 source files. They are included in the integration input list and archive.
The standalone native guard is integrated under test/ and passes 744 focused checks.

```sh
python3 tests/constructor_implied_do/inquiry-followup/run_tests.py \
  --gfortran /absolute/path/to/gfortran \
  --candidate /absolute/path/to/frozen/interpreter
```

Either tool can run separately. GNU never executes a negative fixture. Sources
and expected stdout have hashes in `manifest.json`. Reproduce the research with
`run_probes.py --gfortran PATH` and `run_shape_probes.py --gfortran PATH`, followed
by `generate_manifest.py`. The generator verifies each source hash before using
its GNU output. CHARACTER output is byte-exact; numeric comparisons use the
main suite's strict integer/Decimal comparator. The constructor candidate passes all 22 cases, including the 19 GNU execution comparisons.

## Valid cases

- Own-index KIND, DIGITS and HUGE controls, their `(i+1)` operand forms,
  INTEGER8 KIND/DIGITS, and KIND used in start/end/step.
- INTEGER, REAL(8) and CHARACTER PARAMETER constructor initializers, plus an
  ordinary initialized array. These are fixed-size, fixed-length probes, not a
  claim for arbitrary specification expressions or dynamic constructor lengths.
- LEN of nonempty/empty untyped fixed-length CHARACTER constructors and undefined
  CHARACTER array elements. LEN must not require their data values.
- Nested outer controls using SIZE([(j,j=1,KIND(i))]),
  KIND([(j,j=1,i)]) and LEN([("ab",j=1,i)]). The outer i is pending; the inner j
  has its own lexical scope. KIND/LEN need no inner extent value here, while
  SIZE needs enough information to determine the inner extent.

All 19 valid cases have strict GNU14.2 execution references with empty stderr.

## Scope and inquiry distinctions

The rule against own-index control references concerns references requiring the
index's **value**. Its scope still covers the complete implied-DO, so a direct
read cannot access an outer i. [J3/18-007r1 §16.1 paragraph 2](https://j3-fortran.org/doc/year/18/18-007r1.pdf)
permits undefined argument values for intrinsic inquiry functions. Thus
KIND(i)+i and SIZE([(j,j=1,i)]) reject because they still require the pending
outer index's value, unlike the valid metadata-only cases above.

GNU accepts a same-name inner index in SIZE([(i,i=1,3)]) inside outer i's
control. This is **compile-only**, never a valid-language execution oracle:
§7.8 C7115 and §19.4 paragraph2 prohibit a repeated statement-entity name inside
the enclosing implied-DO scope. Its maintained expectation is subset/scope
rejection; GNU acceptance is retained transparently. Together with the two GNU
compile-rejection cases, this yields three non-executed negatives.

If a valid positive remains outside the interpreter subset, document that
boundary explicitly rather than calling its source invalid or weakening the
oracle. Verification evidence is in verification.json; successful bounded coverage does not imply full-library support.
