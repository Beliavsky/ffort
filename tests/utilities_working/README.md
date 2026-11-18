# User-authorized reduced-capacity utility working copy

The user explicitly requested changing `nmax = 10**8` to `nmax = 10**5` for now.
`xutilities-nmax-100000.f90` makes exactly that one-byte change at original line
9328. The 338,883-byte size, all CRLF line endings, every procedure body outside
that digit, and the original file in `tests/utilities_slices/source` are retained.
This file is labeled an **adapted working version**, not unchanged upstream input.
The interpreter's array and execution limits are not increased.

The whole adapted program freshly compiled and executed under GNU Fortran 14.2
with explicit GNU dialect (`GETCWD` is a GNU extension), exit 0 and empty stderr,
in the separate 0.54 fifth-preview verification. The exact flags remain
`-std=gnu -O0 -fcheck=all -fbacktrace -ffree-line-length-none`, with no fallback.
This does not establish FortFront compatibility or cross-processor random/time
value equality. Historical GNU runs remain preserved separately.

## Current 0.57 READ-sections development boundary

The READ-sections candidate advances checking and the run command past internal
READ targets at 3084/3087 and CHARACTER targets at 3196/3199 to **3550:30**:
`jmat=imat(jrow_use,jcol_use)`. Both return status 1 and empty stdout with
`Vector subscripts support only rank-one INTEGER row indices of a matrix`.
Both matrix axes use vector subscripts; this remains outside this checkpoint.
No whole-program interpreted execution begins. This is a development boundary,
not a full clean certification or successful whole-program run.

The candidate SHA256 is
`2d47a3913ad6cc9145bbbe02e6e5af9739eb6ecc9818af9de0198038d0a714f8`.
The authorized working source remains byte-identical, SHA256
`69d8d20740044c26482ff0193adc6cd5ba85aa351d5c49f04359ebee2918f914`;
original SHA256 is
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
The separate checkpoint evidence records both commands in
`candidate02-utilities.json`, with exact stderr/stdout receipts. See the
[READ-sections contract](../../docs/INTERNAL-READ-SECTIONS.md).
Historical maintained harness gates below are not silently repinned by this
focused development observation.

## Historical 0.54 evidence

With bounded registered-input-only `INQUIRE(UNIT=iu,NAME=file_name)`, the observed
0.54 fifth-preview source gate advances to 2995:41:
`External READ requires an INTEGER unit variable, list-directed whole local numeric or CHARACTER targets or literal (A) scalar CHARACTER, and optional INTEGER IOSTAT outside PURE/SIMPLE procedures`.
Both `--check` and the run command stop with status 1 and exactly empty stdout.
This is a source/check boundary: the complete program never begins interpreted
execution. The measured candidate SHA256 is
`14a7d889568e7bf8233dbaeff67311e14d8502391b72b00ca1332a12078d17d2`.
This focused verification does not replace the complete clean release checks.
The run explicitly uses `--max-steps 100000000` as two arguments; the default
budget and array cap are unchanged. READ to a CHARACTER array element remains
outside this checkpoint. INQUIRE uses only caller-registered input metadata,
without host-unit discovery or arbitrary file access.

The previous runtime-unit WRITE gate at 1208:8 and intrinsic REPEAT call at
2114 are separately covered by bounded focused tests. These advances do not
establish successful full-program execution or arbitrary file access.

The harness records the GNU full run separately from the expected FortFront
boundary. It verifies candidate identity before/after, the exact diagnostic and
source bytes. Future feature support must deliberately migrate this stage
expectation while keeping this authorized source adaptation byte-identical.

Run `python tests/utilities_working/test_runner.py` for18 source-preservation,
exact-diagnostic and historical-evidence checks.
Run `python tests/utilities_working/run_tests.py --candidate PATH --gfortran gfortran`
for the original/working identity proof, expected current FortFront gate, and
independent full GNU compile/run. `provenance.json` contains portable identities.

The previous 0.44 GETCWD gate at553:12 and intermediate external READ gate
at601:10 have advanced through explicitly tested features. The source and
one-byte provenance remain unchanged. The 0.49 observation at 2376:11 is retained
byte-for-byte in `oracle-evidence/0.49-results.json`. The 0.50 metadata-only
migration advanced that expectation to 2493:24 without changing either source.
The certified 0.51 result at 2493:24 is retained byte-for-byte in
`oracle-evidence/0.51-results.json`. The 0.52 metadata-only migration advances
the expectation to 2678:36, with both Fortran files and provenance unchanged.
The unchanged original still rejects at 9329:55 with the 1,000,000-element
array-storage cap; the adapted file does not waive other interpreter limits.
Neither a successful source check nor a focused closure is substituted for a
successful whole-program run.

The0.45 constructor gate at686:30 is now covered by the exact original compare_vec_strings wrapper; this does not establish full-program compatibility.

The certified0.52 result at2678:36 is retained byte-for-byte in `oracle-evidence/0.52-results.json`. The separate numeric-only0.53 metadata migration advances the expected gate to2992:1 INQUIRE without changing either Fortran source or provenance. Applying this migration to a later combined release requires rechecking that release’s actual first gate.

The certified 0.53 result at 2992:1 is preserved byte-for-byte in
`oracle-evidence/0.53-results.json` (SHA256
`1a06560b5decfcc6dfd4d66b2e6e108ed3410c998cf4b6290a61766c7e98581e`).
This separate 0.54 metadata-only migration advances the expected source gate to
2995:41 without changing either Fortran source, the one-byte provenance, any
prior result, or GNU dialect/flags. The unchanged original retains its separate
9329:55 array-storage-cap observation. Fresh fifth-preview working check/run and
full GNU results are in `oracle-evidence/0.54-preview-results.json` (SHA256
`3cb3d739d304c3a97b58a027ee17ab7dcaf9b15d73b02486960a7c8685aac78e`).
The old metadata draft and all earlier preview results remain preserved outside
this maintained overlay. READ array-element support is not part of this release
scope; a later implementation must deliberately migrate the expected gate.

## 0.55 development gate advance

The unchanged authorized working source now rejects at 3000:27: `Internal READ requires a scalar CHARACTER variable, distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT`. Both check and run return source status1 with empty stdout. This advances past the external READ-element blocker but is not full-source execution. The 0.54 gate and all earlier measurements above are preserved as history.
