# Internal READ from a whole local CHARACTER element: focused contracts

This is the maintained 0.56 integration suite. All 51 contracts passed in the preserved focused preview retaining its 0.55 banner; versioned full clean certification remains pending.

51 cases: 28 exact GNU executions, 21 compile-only references, and two exact GNU constraint rejections. GNU support for a case does not imply interpreter support. Sources are newly written synthetic fixtures, including a utilities-shaped loop; no original utility body is claimed here.

Candidate successes require check exit 0 with empty streams and run exit 0 with exact `OK\n` stdout and empty stderr. All 23 compile/runtime negative diagnostics are exact observed, independently reviewed pins. The original unpinned and failed runs remain separate evidence. The first GNU run retains the two expected unpinned rejection failures. The successor pins their actual diagnostics without changing source bytes, stage, or expected execution.

Scope: complete local fixed-length CHARACTER elements, fixed/allocated arrays ranks 1–3, scalar INTEGER literal/local-name/arithmetic indices. The suite intentionally excludes intrinsic/user-call indices, target/IOSTAT-dependent indices, automatic/deferred-length/dummy/host/saved file bases, pointers, sections, substrings, whole-array and arbitrary expression files. Scalar legacy input behavior is separately covered by unchanged internal READ suites.

Transfer controls cover quotes, null/repetition/slash fields, arrays and numeric kinds, IOSTAT success/error/EOF, empty target lists, zero/max record length, only the selected element defined, unchanged file storage, repeated reads, external `(A)` composition, and BACKSPACE cursor behavior. Runtime safety references cover undefined records/indices, bounds, unallocated storage, embedded newline, and missing IOSTAT.

The strict runner is adapted from the delivered 0.55 external-element harness, with explicit SHA binding, source/policy identity before/after, raw stdout/stderr capture, exact path diagnostics and exclusive output targets. Thirty pure selftests run normally and under `-O`.

For integration, copy only `cases/`, `run_tests.py`, `test_runner.py`, `generate.py`, `manifest.json`, `provenance.json`, and this README. Do not copy GNU executable evidence trees as source. Preserved initial manifests and GNU runs belong in separate development proof.

The new program-contained PURE exemption is deliberately narrower: scalar nonallocatable INTEGER/REAL/CHARACTER targets and INTEGER IOSTAT only, with direct writable local or permitted OUT/INOUT dummy storage. It does not introduce host writes, effectful index calls or general PURE I/O relaxation.
