# CHARACTER arrays

Run `python3 generate_cases.py` to regenerate the 49 deterministic cases and
manifest. Then use `python3 run_tests.py --candidate /path/to/fortfront-interpreter
--gfortran /path/to/gfortran` to run both implementations. The generated results
include executable, source and manifest hashes and per-case compiler evidence.
The independent expectations cover fixed-width padding/truncation, concatenation
precedence and scalar expansion, constructors, arrays/sections, overlap, PARAMETER
values, inquiry-only evaluation and clean failures. List-directed comparisons
ignore compiler-dependent whitespace; native tests additionally assert exact
stored character widths using concatenated delimiters.
