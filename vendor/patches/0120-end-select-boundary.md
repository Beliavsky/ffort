# 0120: do not rescan a consumed END SELECT keyword

`parser_statement_detection.f90` resumes its scan after a two-token END SELECT.
Previously the restart position pointed at the already-consumed SELECT token.
If a containing SELECT's next CASE followed, the lookahead mistook that token
for a new SELECT CASE opener. The phantom nesting level caused an enclosing IF
body to be sliced past its true SELECT terminator, rejecting valid source.

After closing a nested SELECT that does not finish the current statement, skip
the consumed SELECT token before restarting. The matching outer terminator still
returns its original position. No source, literal, keyword spelling, AST rule,
execution-engine behavior or other construct-closing rule is changed. The same
scanner now folds only keyword comparisons (END/IF and keyword dispatch) to
lowercase, so uppercase or mixed-case construct spelling has identical boundaries.
The IF-body handoff also folds its IF keyword comparison before requesting the
full construct slice; otherwise uppercase IF with ELSE was truncated early.
The shared statement-body end matcher likewise folds END, CASE and the
terminator suffix keyword, avoiding uppercase CASE/END SELECT consumption as
ordinary statements. Token text, identifiers and string literals are not rewritten.

Reproducer: outer IF containing SELECT, whose first arm contains nested SELECT
and IF, followed by outer CASE DEFAULT. Compiled gfortran accepts this source;
the prepatch tokenizer boundary probe pointed at outer END IF instead of outer
END SELECT. Independent oracle regressions cover this layout and casing,
comments, consecutive SELECT and sibling DO/IF constructs. Compact ENDSELECT
remains outside the interpreter parser grammar in this preview; separate
negative coverage checks rejection without pending effects. Use END SELECT.
