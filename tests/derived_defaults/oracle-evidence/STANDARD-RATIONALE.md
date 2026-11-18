# Empty derived-result observations: standard rationale

Primary source: [J3/23-007r1, draft Fortran 2023](https://j3-fortran.org/doc/year/23/23-007r1.pdf).

* Clause 7.5.4.6, pp. 81–82, associates a component constant initializer with
  each object of that type, without giving the object SAVE.
* Clause 19.6.5(23), p. 549, defines nonpointer default-initialized subcomponents
  of unsaved, nonpointer, nonallocatable local variables on procedure invocation.
* Clause 15.6.2.2, pp. 339–340, identifies RESULT(r) as the returned entity;
  its accompanying Note 1 explains its local, per-invocation lifetime. R1532
  permits an absent execution part. Return requires a defined nonpointer result,
  not necessarily an explicit assignment statement.

For these two sources, r is scalar, unsaved, nonpointer and nonallocatable.
Its only component has the constant default 7. The invocation rule therefore
provides its defined value before any executable statement. The empty body
cannot overwrite it. PURE adds no exception to that initialization rule.
The independently expected result is thus 7, for both ordinary and PURE make().
This reasoning does not initialize other components lacking defaults.

## Preserved observations, not GNU execution agreement

`empty-result-profile-disagreement.json` retains the original source hashes,
compiler identity, exact argv and raw streams. GNU Fortran 14.2 at both `-O0`
and `-O2`, with `-std=f2018 -pedantic-errors -fcheck=all`, compiled and exited
successfully but printed `0\n` for both `default_function_result` and
`pure_default_function_result`. Stderr was empty. The candidate printed `7\n`.
These two cases remain GNU **compile-only** in the ordinary runner. Their four
separately retained executions are observations of a discrepancy, never counted
as GNU execution agreement. Nonempty function-result bodies are separate tests.
