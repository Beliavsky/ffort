# SELECTED_REAL_KIND and reduced utilities

The interpreter implements `selected_real_kind([p, r, radix])` for its supported
binary REAL kinds: kind 4 has decimal precision 6 and exponent range 37; kind 8
has precision 15 and range 307. It chooses the smallest adequate precision.
Arguments must be scalar INTEGER (kind 4 or 8). They may be positional or named,
with positional arguments before keywords. All three arguments are optional:
missing P/R are zero and missing RADIX accepts the available binary kinds.
The no-argument call returns 4. Duplicate/unknown keywords, excessive arguments,
arrays and noninteger arguments are rejected before output.

The result is default INTEGER. Unsatisfied requests return -1 for precision,
-2 for exponent range, -3 for both, and -5 for an unavailable radix. The -4 case
cannot arise for this model because kind 8 dominates kind 4 in both precision
and range. Requests such as P=16 or R=308 return a negative code even when GNU
Fortran on the host offers wider kinds. This does not add REAL(10), REAL(16),
or any other storage kind to the interpreter. The pinned frontend continues to
know about wider source kinds; the interpreter's supported-kind boundary remains
independent and explicit.

Calls work in runtime expressions and constant expressions, including PARAMETER
initializers and direct `real(selected_real_kind(...))` declarations. KIND can
inquire about the INTEGER result without evaluating undefined inquiry arguments.
Argument-slot metadata is checked independently against the producer AST and is
validated by the runtime. The strict frontend registers the intrinsic and resolves
P/R/RADIX keyword slots for kind metadata, without bypassing semantic checks.

## Utility-source assessment

`tests/utilities_slices/source/xutilities.f90` is the untouched 338,883-byte,
9,806-line input. `source_parts/source-map.json` partitions every byte into the
kind module, utility specification, 549 top-level routine fragments (retaining two internal procedures), module ending, main
program declarations, eight complete-statement driver blocks, and program ending.
`split_source.py --check` verifies exact byte-for-byte reconstruction, including
CRLF line endings. These reference fragments retain their original dependencies;
they are not advertised as independently compilable modules.

The standalone harnesses at `tests/utilities_slices/*.f90` test smaller units.
See [the quick-start commands](../tests/utilities_slices/README.md).
The original smaller groups retain 15 unchanged routine bodies (apart from
newline normalization). This release also executes the former OPTIONAL,
COUNT/DBLE, MERGE, INTEGER(8) DO, ELSE IF, EXIT and COSH boundary harnesses without
rewriting their algorithms. Historical `blocked_*` filenames remain stable;
the manifest now classifies supported cases as executions.

Additional source-mapped suites exercise seven exact OPTIONAL routines,
`int_in_vec` and `notall` with ALL/ANY and defined operators, the complete
original `kind_mod` declaration forms and chained utility constants. The release
integration corpus combines these retained modules with a new driver and wrapper
using module dependencies, omitted optionals, named wide loops, ELSE IF,
EXIT/CYCLE and logical intrinsics. Each component's source map identifies source
ranges and normalized body hashes. Older wrappers still declare some constants
locally; newer module tests explicitly cover the original declaration forms.

The new [array-result suite](../tests/array_results/README.md) executes the exact
original bodies of normalize, diff_vector_int, diff_vector_real, diff_matrix_real,
growing_mean_vec and num_obs_bins. The historical normalize and sech boundary
harnesses now execute. A separate automatic-local fixture retains true_pos_count
with an adapted caller; its provenance distinguishes the adaptation from original code.

The [COUNT/PACK/RESHAPE integration](../tests/count_pack_reshape_integration/README.md)
retains exact original true_pos_func, positive_int_vec, vector and matrix_from_vec
bodies. Its new driver combines selection, reshaping, ordinary array results,
sections, reductions and matrix products. Source hashes and original line ranges
are checked independently; these wrappers do not replace the original main program.

The [location-intrinsic suite](../tests/location_intrinsics/README.md) now executes
the unchanged original `iminloc` body, including its DIMENSION attributes,
reverse sections and empty inputs. [MINLOC/MAXLOC](LOCATION-INTRINSICS.md) support
numeric rank-one/two sources, DIM, MASK, KIND and BACK within documented limits.

The [CHARACTER intrinsic suite](CHARACTER-INTRINSICS.md) retains the exact original
`quote` body and executes its LEN_TRIM-based result length. INDEX, LEN_TRIM,
ADJUSTL and ADJUSTR now support bounded scalar/rank-one/two execution; these
focused fixtures do not imply support for every routine that calls them.

The complete utility file is not executable in this prototype. It currently
fails before output at the fixed-array resource cap (line 9329, column 55), after
passing the source and metadata capacity gates and recognizing its defined-operator syntax.
The enlarged metadata defaults are independently tested with 423 PUBLIC/ONLY names,
551 procedures, 124 generics and 2,997 symbols; this is not a claim that the
original procedure bodies all parse. See [METADATA-LIMITS.md](METADATA-LIMITS.md). Further known
boundaries include recursive ELEMENTAL procedures, unlisted intrinsics, allocation forms outside the bounded numeric/LOGICAL/CHARACTER rank-one/two/three subset, rank-four and higher arrays, re-export of imports, and general formatted/file I/O.
The source remains retained byte for byte, and the boundary is tested in check
and run modes. Supporting these smaller bodies is not a full-utilities claim.

GNU Fortran 14.2 compiles and runs the untouched input in its default mode. Strict
`-std=f2018` rejects its nonstandard ISNAN call at source line 8883. The original
driver intentionally reaches `check_all_equal([2,3],...)` and prints its stopping
diagnostic. Those source properties are separate from interpreter limitations.
Exact commands, statuses and log hashes are retained in
[the preserved verification-history index](VERIFICATION-HISTORY.md):
`docs/verification/0.19.0/original-file-evidence.json`, in the unchanged 0.46 ZIP.

## Verification

Run `fpm test --profile debug`, then
`python3 tests/utilities_slices/run_tests.py --candidate PATH_TO_INTERPRETER`.
The focused suite retains 33 cases; the manifest and results classify direct
GNU comparisons, expected source rejects and the supported-kind-model check.
The wider 0.22 suites and combined original-body checks are summarized in
[VERIFICATION.md](VERIFICATION.md).
The new native test checks seven adapter cases, seven runtime value cases
(two assertions each), 17 malformed-runtime cases, and five additional
valid/unevaluated checks: 43 assertions total.
A separate producer test checks three valid zero-argument direct kind selectors
and rejection of three other empty calls.

The API semantics are based on the GNU Fortran intrinsic documentation:
https://gcc.gnu.org/onlinedocs/gfortran/SELECTED_005fREAL_005fKIND.html

The allocatable milestone independently executes the unchanged original
`alloc_sub_vec_int` and `alloc_sub_vec_real` bodies with first allocation, OUT
replacement and zero extents. See `tests/allocatable_dummies` and
[ALLOCATABLES.md](ALLOCATABLES.md). This does not claim full-file support.

The [rounding suite](../tests/rounding_intrinsics/README.md) retains exact original
`floor_10` and `ceiling_10` bodies. NINT/FLOOR/CEILING and LOG10 are independently
verified; this does not claim that other utility bodies or the full input execute.

The [FORALL suite](../tests/forall/README.md) retains six original bodies
(`repeat_int`, `repeat_real`, `ivec`, `diag`, `matrix_by_vector_real` and
`sign_changes_real`). The [0.26 integration suite](../tests/release026_integration)
combines original `munge`, `floor_10`, `ceiling_10` and
`set_alloc_character_vec` bodies with new allocation and snapshot-assignment
drivers. These provenance-checked wrappers do not replace the original source.

The OPTIONAL numeric/logical-array suite preserves the original real allocation
helper bodies and executes them in a new wrapper. Its combined real/integer
original slice now executes all four preserved bodies, including the pure
recursive integer helper. [RECURSION.md](RECURSION.md) documents its bounded
activation and focused filter tests. The scalar `strip` body is tested unchanged in its own
wrapper, and five original CHARACTER utility bodies compose in the new release
integration driver. None replace or rewrite the full original library.

The 0.28 milestone executes the exact original `tensor` body and the recursive integer allocation helper. WHERE fixtures preserve original `lag` and `madev` bodies but explicitly substitute a harness assertion helper and, for madev, an NMA=0-only equivalent dependency. The ratio-default uninitialized MERGE branch remains an expected runtime rejection. SCAN/VERIFY evidence uses two exact expressions from `get_numbers`, not the complete routine. See [WHERE.md](WHERE.md), [RANK-THREE.md](RANK-THREE.md), and [CHARACTER-SEARCH.md](CHARACTER-SEARCH.md).

## Historical 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input was reduced to bypass the boundary at that checkpoint. External READ/CLOSE
were unsupported there; bounded explicitly bound READ is now supported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).

## Historical 0.50/0.51 utility boundary

The untouched original retains its 9329:55 fixed-array storage-cap rejection.
The separately authorized working copy changes exactly one byte, nmax=10**8 to
nmax=10**5. The bounded array-element internal WRITE and numeric rank-three
gather additions advanced it to the parser boundary at 2493:24, rank-one
CHARACTER vector gathering in `select_vec_character`. That feature was
not included in 0.50/0.51. Neither checkpoint successfully checked or executed
the entire utility program; later adapter/runtime validation remained unproven.
The original routines and both full
sources remain unchanged except for that explicitly identified working-copy byte.


## Historical 0.52 utility boundary

The authorized one-byte `nmax=10**5` working source now passes the CHARACTER
selection forms at lines 2493 and 2523 through the bounded
[CHARACTER gather](CHARACTER-GATHER.md) and
[read-only bare-actual](BARE_CHARACTER_GATHER_ACTUAL.md) contracts. Focused
original-body closures preserve their documented dependencies and wrapper
substitutions; they are not complete-library execution evidence.

Both `--check` and the run command still reject the full working source at
2678:36, `Vector subscripts support only rank-one INTEGER row indices of a matrix`,
on `call set_alloc(ivec(ipos(:nuniq)),jvec)` in `unique_vec_int`. Numeric rank-one
gathering is not added. This is a source-stage boundary, so interpreted execution
of the full program has not begun. The untouched original still rejects at
9329:55 under the unchanged configured element cap. GNU's separate full working
program compile/run does not establish FortFront compatibility or identical
random/time results. See [the working-source contract](../tests/utilities_working/README.md).

## 0.53 utility boundary

Historical 0.53 checkpoint: The 0.53 numeric rank-one extension advances the byte-preserved adapted working source to 2992:1, `INQUIRE`. This is still a source-stage rejection, not interpreted whole-program execution. The untouched original retains its 9329:55 resource-cap rejection. INQUIRE is excluded from this checkpoint; no file-access or ordinary-function effect policy is relaxed.

Focused original `unique_int` and `set_alloc_int_vec` bodies are separate evidence. The full `unique_vec_int` dependency closure still hits the retained transitive ordinary-function external-WRITE restriction. Advancing full-source checking to INQUIRE does not establish that closure or whole-program execution. See [numeric rank-one gathering](NUMERIC-VECTOR-GATHER.md).

## Current bounded input-name inquiry

The focused 0.54 composition adds only [registered input NAME inquiry](INQUIRE_NAME.md). The byte-preserved adapted working source now stops at 2995:41 on external READ to a CHARACTER array element; the untouched original still stops at 9329:55 under the unchanged array cap. Both remain pre-execution source rejections. See the [working-source evidence](../tests/utilities_working/README.md). READ-element support remains outside this checkpoint, and no host-unit discovery, general file access, writable-actual or ordinary-function effect relaxation is implied.
