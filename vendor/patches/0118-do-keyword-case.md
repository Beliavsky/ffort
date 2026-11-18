# 0118: case-insensitive DO construct keyword boundaries

Applies after 0117. DO body scanning and matching previously compared several
keyword token spellings directly, causing uppercase or mixed-case DO/END DO/
ENDDO to lose construct boundaries. Use the already-imported `to_lower` only
for DO parser keyword comparisons and dispatch. Source and token text are not
modified; string literals, identifiers and comments retain their original text.

Changed producer files: `src/parser/control_flow/parser_do_constructs_part1.inc`
and `parser_do_constructs_part2.inc`, plus a documentation comment in
`parser_do_constructs.f90` (also ensuring incremental rebuilds notice this
include-only logic change). The second file shares DO/DO WHILE body
boundary handling; this fix does not expand retained-session loop admission.
Retained sessions continue to admit only unnamed counted DO, not DO WHILE,
bare DO, EXIT/CYCLE or named constructs.

Regression: `test/test_do_keyword_case_frontend.f90` checks all combinations of
lowercase/uppercase/mixed-case DO and END DO/ENDDO with nested loops through
both parsers, and verifies mixed-case string literal contents survive execution.
This is a localized development-preview parser correction, not a new release
or full vendor test-suite certification.
