# Mutable module regression corpus

Run `python tests/mutable_modules/run_tests.py --candidate PATH --gfortran gfortran`.
The manifest carries independent expected output and separates valid execution,
compile-only subset restrictions, compiler-invalid source and interpreter-only
runtime safety checks. GNU is only an independent oracle, never the interpreter
execution backend. See ../../docs/MUTABLE-MODULES.md for scope and limitations.
