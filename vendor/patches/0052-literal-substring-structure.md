# 0052: Preserve literal substring structure

Local MIT-licensed FortFront corrections, based on the final 0.30 vendor tree
through patch 0051. Replay at the vendor root using `patch -p1 --fuzz=0`.

A constant literal substring now retains an array-slice node with the original
literal base and range. Previously the parser replaced that expression with a
new folded literal, losing source structure needed by an independent adapter.
Existing checks for syntax, scalar integer bounds and invalid nonempty constant
ranges remain active. Dynamic and escaped-quote cases continue through their
existing retained-slice paths. The interpreter independently verifies source
literal contents, bounds and canonical scalar CHARACTER metadata.

The control-keyword dispatcher is marked RECURSIVE. An inline IF with EXIT inside
a procedure loop already re-enters this routine through its existing callbacks;
GNU `-fcheck=all` identified the missing annotation while exercising the synthetic
digit formatter. No dispatch behavior or semantic validation is changed.

This does not add all expression-base substrings, broad constant folding,
unbounded DO, REPEAT or complete original utilities execution.
