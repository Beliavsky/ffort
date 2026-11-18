# 0111: distinguish conditional DO from iterator WHILE

Apply with patch -p1 inside vendor/fortfront after baseline0.50 ledger0110.
This reconstructed patch changes only parser_do_constructs_part1.inc. Both
conditional-loop dispatch paths now require keyword WHILE followed by opening
parenthesis, skipping horizontal whitespace only. Thus a counted iterator named
WHILE remains a counted DO. Existing loop parent restoration from0108 is kept.

The project-root patch remains SHA256
f259648c94dd0a6706cb75a7aa063090885b52a16f465405585be37bfa4cf223.
This canonical patch changes path prefixes only. It was reconstructed after
workspace loss; its fresh identity is not claimed equal to the earlier0111.
Read-only independent review passed and fresh merged preview source/native
checks passed. Full release certification is separate. No fixture source or
historical baseline ledger is rewritten by this patch.
