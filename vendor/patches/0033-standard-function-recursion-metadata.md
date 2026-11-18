# Preserve written recursion metadata in STANDARD input

FortFront's lazy-source token heuristic treated every occurrence of a procedure
name followed by `(` as a recursive call. For an ordinary array-valued function
without RESULT, a declaration such as `integer :: f(n)` and a result subscript
such as `f(i)=i` therefore added an unwritten RECURSIVE prefix. The strict adapter
correctly rejected the altered metadata.

In STANDARD mode, keep only explicitly written recursion prefixes. Existing
lazy-input inference is unchanged. The interpreter independently rejects direct
and indirect call cycles, so this correction does not admit recursion. The patch
uses the existing input mode set before parsing by vendor patch 0001; it neither
rewrites source nor bypasses semantic checking.

Coverage: tests/array_results/implicit_result.f90 and
`test/test_array_result_producer.f90`. The latter checks standard/lazy/standard
mode transitions and explicit RECURSIVE preservation. The complete upstream
FortFront suite is not claimed to have been run.
