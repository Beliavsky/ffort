# 0110: retain semicolon-separated CASE bodies

The CASE-arm producer previously skipped all remaining tokens on the header's
physical source line, including valid body statements following `;`. The
independent adapter correctly rejected the resulting missing statements. The
exact original select_tensor_real utility has three such CASE/call lines.

Add an optional semicolon stop to the existing line-skip helper and enable it
only at the CASE value/default header sites. The separator is consumed, but
following statement tokens, physical locations and body ownership remain for
the ordinary statement-body parser. Other SELECT TYPE/RANK callers preserve
their existing behavior. No adapter check, source body, intrinsic scope, output
behavior, resource cap, or registry entry is relaxed or changed.

Apply this raw patch once in vendor/fortfront after the 0.50 predecessor
ledger (0108 and 0109). It changes only two parser include files. The pre-fix
failure reproduces on certified 0.49 and the initial corrected 0.50 preview.

Coverage: tests/rank_three_vectors contains fourteen independent GNU CASE fixtures
(inline calls/assignments, DEFAULT, same-line arms, nested
IF/DO/SELECT, literal/comment/repeated semicolons, actions after END SELECT, LOGICAL/CHARACTER selectors and ordinary multiline
control), plus exact original utility closures. The native
test/test_rank_three_vectors.f90 checks all three action bodies, exact physical
line/column, and forged adapter-location rejection. See the suite's verification
receipt for observed execution identities and counts; patch applicability alone
is not execution proof.

The continued CASE-header fixture is GNU-valid but retains a pre-existing
producer physical-line mapping boundary. Its source and GNU execution are
preserved, and the exact adapter rejection is pinned independently. This patch
does not opt CASE bodies into a new continuation-location mapping policy.
