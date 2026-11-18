# Whole-source metadata capacity

The shared build-time constants in `src/fi_limits.f90` configure these independent
limits. Change a constant, clean the build and rebuild to choose another cap:

| Constant | Default | Scope |
|---|---:|---|
| `max_symbols` | 8,192 | All declarations, dummies and implicit typed results in one source |
| `max_procedures` | 1,024 | All module and internal procedures in one source |
| `max_generics` | 256 | All named generic interfaces in one source |
| `max_access_names` | 1,024 | PUBLIC names and, separately, PRIVATE names in each module |
| `max_only_names` | 1,024 | Names in one USE ONLY list |

These caps do not raise the source-byte, token, expression, instruction, module,
array-element, generic-specific (16), procedure-argument (16), or active runtime
call-depth (64) limits. A source can hit an independent limit first. Counts must
remain positive default INTEGER values and fit available memory. Very large
values are not an unlimited-support claim.

Symbols, procedures, generic records and USE ONLY names are allocatable IR
components. Parser PUBLIC/PRIVATE name tables are also heap allocated. Allocation
failures return diagnostics. The default ONLY-name matrix is about 8.4 MiB and the
two accessibility-name matrices together about 2 MiB; neither is embedded in
`program_t` or a stack frame. IR assignment owns an independent copy of these
allocatable components. Runtime arrays remain sized by actual IR counts, not the
metadata maxima. Their storage still scales with all source declarations per
active frame, so large sources and deep calls use more heap memory.

Call-graph validation uses a heap-allocated sparse adjacency list and an iterative
reachability walk. Its storage is O(procedures + calls), and total traversal work
is O(procedures × (procedures + calls)). This replaces the cap-sized automatic
matrix and cubic closure. Cycle rejection and transitive external-effect checks
remain enforced even for unused procedures. The independent adapter still
cross-checks bindings, metadata and the call graph.

## Verification

- `test/test_metadata_limits.f90`: below/at/above all five configurable boundaries;
  long recursion, transitive external effects, missing/short allocatable IR
  metadata, and successful compilation after failures.
- `tests/metadata_limits/run_tests.py`: a runnable source with exactly 551
  procedures, 124 generics, 423 PUBLIC and ONLY names, and 2,997 symbols, compared
  with GNU Fortran; at-cap procedures, symbols and generics; over-cap and cycle
  failures; and the byte-for-byte original utilities boundary.
- The CLI at-procedure-cap fixture has a 1,024-procedure call chain that is checked
  but not executed, preserving the separate 64-active-frame runtime limit.

The untouched 338,883-byte xutilities source reaches the fixed 100-million-element
xbig declaration at 9329:55. It exceeds the configured 1,000,000-element cap and
rejects with no stdout in check/run. This intentional resource boundary is
separate from metadata capacity and later external I/O limitations.

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).
