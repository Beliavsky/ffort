# Default-CHARACTER MIN/MAX

MIN and MAX accept 2–16 arguments of the same supported type and kind. This extension adds default CHARACTER scalars and conforming arrays through rank three, with scalar expansion and A1 through A16 keywords. Sparse higher keyword slots are allowed when A1 and A2 are supplied. The existing INTEGER/REAL kind-4/8 value algorithms remain unchanged. Ordinary data, result, procedure and generic names may shadow MIN/MAX.

For CHARACTER values the selected minimum or maximum uses the processor's intrinsic collating order. The certified platform uses one-byte character codes. Arguments of different lengths compare after right blank padding, and the result always has the longest argument length. This is not Unicode linguistic sorting. Every character length remains bounded to 65536; comparison positions consume the existing execution budget. Existing array and CHARACTER storage limits remain active.

The parser, independent source adapter and runtime validate type, kind, count, shape and length. Runtime guards remain active for static/empty arrays and KIND. Memoized operand walks reject cycles and forged declarations, literal caches and function-result metadata while accepting shared DAGs. KIND does not read data. LEN uses operand lengths and does not evaluate fixed-length data values; unknown function-result lengths may require evaluation. Missing, uninitialized or unallocated values still fail when evaluated. Wider CHARACTER kinds, mixed type/kind arguments, more than sixteen arguments and keyword numbers above sixteen remain unsupported.

## Originals and the GNU 14.2 limitation

The full unchanged `demo_max.f90` executes correctly. Its CHARACTER array result is BB and Z followed by one blank, both length two, and its embedded success check passes. `demo_min.f90` remains a constructor-dependent rejection in this standalone feature. The explicit `--with-constructors` suite profile promotes it only when that companion implementation is installed; the expected two-element result is YY and A followed by one blank, both length two.

These are independent-oracle original results, **not GNU 14.2 execution agreement**. Strict GNU Fortran 2018 rejects both original constant-array calls with an erroneous element-length diagnostic. GNU/default or legacy modes compile them but truncate selected elements and fail the originals' own checks. Other recorded GNU 14.2 limitations include compiler crashes on deferred-length array assignment or array length/type inquiries. Each such fixture has a specific expected compiler status/diagnostic and independent candidate expectation. Ordinary cases retain strict GNU differential checks. No generic output comparator was relaxed.

The Fortran 2018 interpretation draft [J3/18-007r1](https://j3-fortran.org/doc/year/18/18-007r1.pdf), sections 16.9.125 and 16.9.131, specifies the longest result length and right blank padding and gives the exact array calls used by both originals as examples. [Intel's official MAX reference](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2025-0/max.html) independently confirms that rule. Full expected records, source hashes and strict/permissive GNU evidence are in `tests/character_minmax/oracle-evidence/`.

## Validation

- 106 focused source outcomes: 54 strict GNU executions, 24 matching source rejections, 16 GNU compile-only bounded cases, and 12 separately classified known GNU limitations.
- 273562 assertions in the directly linked native test, including all 131072 family/one-byte-pair evaluations and 3200 varied-length multicharacter comparisons.
- 18 direct producer metadata/shadow checks; producer source is unchanged, so reserved vendor number 0092 is unused.
- 33 adversarial runner tests cover exact string records, signed zero/Decimal distinctions, empty-output/stderr leaks and individually guarded GNU compiler defects.
- 647 existing related source cases passed across eight suites, with historical source files untouched.
- Only an app/library debug build and two directly linked native test targets were run here, not a full native aggregate. Release integration owns the final clean combined verifier.
