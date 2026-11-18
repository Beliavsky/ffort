# Assignment counter isolation regression

This additive regression extends the original 150-case inverse trigonometric
suite to 222 cases. The original 150 source files and frozen results.json remain
byte-for-byte unchanged. The original results document the pre-composition
coverage; assignment-regression-results.json records the expanded fixed run.

An independent composition exposed an undeclared local temporary in
intrinsic_value: its operand loop used execute_frame's host-associated `j`,
which is also used by array assignment. Direct output and scalar-only tests did
not expose the defect. Three representative whole-array assignments in the
original candidate fail with runtime exit 2 at its ordinary default budget.
The correction is a local temporary declaration, outside this tests-only delta.

The 72 added source cases cover all four call forms (ASIN, unary ATAN, binary
ATAN, ATAN2), both real kinds, and:

- Whole-array assignment at each length from one through five: 40 cases.
- Reversed-input to strided-output assignment with untouched sentinels: 8 cases.
- WHERE/ELSEWHERE array assignments: 8 cases.
- FORALL element assignments with preserved index state: 8 cases.
- Repeated DO-loop whole-array assignments and independent counters: 8 cases.

All 72 execute the original source through GNU and the candidate with no raised
runtime budget. The expanded suite has 173 GNU executions, 17 compile-only
boundaries, and 32 GNU rejections. The existing Decimal, signed-zero, source-hash,
exit-stage, diagnostic and stdout checks apply unchanged.

The new native test test/test_inverse_trig_assignments.f90 has 40 generated
fixtures and 160 assertions. Each fixture checks source parsing, frontend
acceptance, execution with a small 2,000-step budget, and execution at the
ordinary default budget. Independent scalar element calculations establish the
expected vector; the interpreted source checks every assigned value and its
independent sentinels. The small-budget run rejects the old regression quickly,
without increasing the production budget or accepting an incomplete result.

Run the normal suite command for all 222 cases. Use --only '^assign_' for the
72 additions, and add --with-named-formats only for a candidate containing the
separate named-format feature. Both profiles retain a single required outcome
for the unchanged complete upstream demo_asin.
