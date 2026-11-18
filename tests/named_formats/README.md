# Named parameter format checks

From the repository root with fpm/gfortran on PATH:

```
python3 tests/named_formats/test_runner.py
python3 tests/named_formats/run_tests.py --candidate /absolute/path/to/interpreter
python3 tests/named_formats/run_original.py --candidate /absolute/path/to/interpreter
fpm test --profile debug --flag '-ffree-line-length-none' --target test_named_formats
```

The standalone original runner expects ASIN to remain unsupported. In a combined
release containing the companion ASIN implementation, use:

```
python3 tests/named_formats/run_original.py --candidate /absolute/path/to/interpreter --combined-asin
```

That flag requires complete unchanged demo_asin execution with exact GNU bytes;
it does not accept the standalone ASIN rejection as a pass. The unchanged SHAPE
original now also executes completely after vector bounds and constructor
support, with byte-exact GNU output. MAXEXPONENT and ACOS retain source
boundaries, while NEAREST retains its finite-range runtime boundary. Source hashes and the MIT license are checked before
both runners. The NEAREST original has a separately recorded nonfinite GNU
reference flag exception; only its prior finite records are compared.

The 50 synthetic fixtures include positive named PRINT/stdout/internal/child
WRITE, imported/host/local parameters, initialized concatenation/alias/REPEAT,
CHARACTER length padding/truncation, unlimited/ordinary reversion and exact output
caps. The later runtime-format milestone promotes four unchanged mutable-name fixtures
to byte-exact GNU execution. Incorrectly typed/shaped formats, out-of-scope
expression forms, malformed formats and dynamic failures remain bounded. Positive output is always
byte-exact; there is no numeric tolerance or whitespace normalization. Four
adversarial harness tests guard that comparison and silent `--check` requirement.

The native test has 33 producer, adapter and runtime assertions, including
coordinated parameter-cache/frozen-format mutation and exact trailing-length
mismatch. The producer retains names; the adapter checks exact source binding;
the runtime validates the lowered immutable format, not the source identifier.
See [NAMED-FORMATS.md](../../docs/NAMED-FORMATS.md) for the supported contract.
