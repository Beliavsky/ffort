# FortFront 0.54.0: bounded INQUIRE, F0 and element substrings

This checkpoint contains three additions:

1. **Registered-input INQUIRE NAME.** `INQUIRE(UNIT=..., NAME=...)` copies cached name metadata from an explicitly registered input unit into a writable whole local scalar CHARACTER target. It does not perform host `INQUIRE`, discover/open filesystem paths or alter the input cursor/endfile position. Check mode does not open input files. Unnamed/unbound units and unsupported target/effect forms retain controlled boundaries. See [INQUIRE NAME](INQUIRE_NAME.md).
2. **F0.d real output.** Finite REAL kind 4/8 values support minimum-width fixed-decimal output, including precision zero, through the documented precision/output limits. Positive-width formats and G0 retain their existing behavior. Formatting and internal-file storage remain staged; prior committed output is not rolled back. See [F0 formats](F0-FORMATS.md).
3. **Scalar CHARACTER array-element substrings.** Complete elements of supported rank-one through rank-three CHARACTER arrays can be read, assigned and passed as bounded read-only actuals. Address/bounds and payload metadata are validated, with definedness and length checks before storage commit. Bare read-only actuals conservatively reserve the whole base array against writable sibling actuals; parentheses create a value snapshot. Sections, vector gathers, writable substring actuals and substring internal files remain excluded. No procedure-effect policy is relaxed. See [array-element substrings](ARRAY-ELEMENT-SUBSTRINGS.md).

The clean maintained run passed 11,507 source-contract outcomes and 281 native programs, with classifications and independent comparisons kept separate in [verification](VERIFICATION.md). The fresh reconstructed M_intrinsics survey remains at 74 ordinary passes; separate categories are not added to that number.

The authorized utilities working copy advances to 2995:41, formatted READ into a CHARACTER array element. The untouched original retains its 9329:55 array-size cap. Full-source FortFront execution is not claimed. External READ-element support remains future work and is not included here.

Historical source preservation has one explicit exception: the existing native `F0.4` expectation changes from rejection to acceptance. The other 13,081 inherited Fortran/include/native/example bodies remain byte-identical. Historical reports, first failures and measured metadata migrations are retained rather than rewritten as original successes.
