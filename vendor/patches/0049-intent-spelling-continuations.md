# 0049: INTENT spelling and continued-comment declarations

The pinned MIT-licensed FortFront producer already recognized `IN OUT` as
`INOUT`. A legal continued attribute with an intervening comment could instead
lose the rest of its declaration and resolve references to the wrong identity.

This patch keeps the original logical statement line across a leading continuation
ampersand after comment trivia. Statement slicing ignores the physical line of
comments/whitespace while still honoring significant logical-line boundaries and
semicolons. Comment tokens and their physical locations are retained.

The INTENT attribute reader consumes retained comment/whitespace trivia around its
parentheses and direction words, never an uncontinued newline. It requires the
complete opening/direction/closing syntax before recording canonical metadata and
rejects unknown, extra or malformed direction tokens. Duplicate/conflicting
attributes still use the existing validation. No adapter identity or intent checks
are relaxed, and unrelated typed-header parameter extensions are not added.

Apply after 0048 with `patch -p1` in the vendor root. The direct producer, adapter
mutation and runtime tests in `test/test_intent_spelling.f90` make 151 checks across
joined/spaced/mixed-case/tab/continued forms and malformed directions. The source
suite records independent GNU checks under unchanged strict flags; tab whitespace
is separately labeled interpreter policy because GNU pedantic flags reject it.
