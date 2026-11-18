# Independent DO WHILE cross-control composition

Ten synthetic sources cover named and nested conditional/counting/bare loops,
SELECT CASE in both nesting directions, condition function effects, array
reduction refresh, false metadata-only conditions with undefined body data,
counted-variable cleanup on RETURN, pending stdout at budget exhaustion and a
mismatched closing name. The ten source files were reconstructed after an
execution-workspace reset; every source SHA-256 matches the retained historical
identity. Their positive expectations were not changed.

Eight sources require exact GNU/candidate execution records. The deliberately
infinite loop is GNU compile-only and must produce a controlled candidate
200-step error while retaining exactly `SAFE` without a newline. The mismatched
END DO name must be rejected by GNU and both candidate modes. These latter
profiles are not GNU execution agreements. No full utility or release
certification claim follows from this focused suite.

The historical transcript records two SELECT-inside-WHILE adapter failures on
candidate 8221410f, followed by all ten profiles passing after vendor 0113 on
41524b06. Raw pre-reset output files were lost and are not presented as recovered
artifacts. New candidate/GNU execution must produce fresh results bound to its
new executable identity before a reconstructed release is certified.

Run:

```
python tests/release051_integration/test_runner.py
python tests/release051_integration/run_tests.py --candidate /path/to/interpreter --gfortran /path/to/gfortran
```

The runner requires silent successful checks, exact stdout bytes/records,
empty successful stderr, and exact source-located diagnostics/statuses for both
negative modes. It checks source hashes and executable identity before/after,
rejects crash/ICE markers, and uses fresh temporary directories. GNU uses
`-std=f2018 -pedantic-errors -fcheck=all -O0`; invalid and infinite references are
never executed. No text, whitespace, numeric or signed-zero normalization is
used. There is no external input or file-output oracle.

The generator reproduces the pinned sources and manifest. Sixteen adversarial
harness methods cover text/record/status/diagnostic/source mutations and
file-only regeneration without relying on empty directories.
