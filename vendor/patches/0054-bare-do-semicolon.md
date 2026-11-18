# 0054: Bare DO before a semicolon

The standard free-form semicolon terminates a statement just as a newline does.
The existing `do_has_no_control` lookahead already recognized a bare `DO` before
newline, EOF, whitespace and comments, but treated `DO;` as a malformed counted
control. Recognize a semicolon token as the end of the bare header, leaving it
for the existing body scanner. Other operator tokens still require a valid
counted control. This changes neither DO WHILE nor DO CONCURRENT semantics.

This is a local MIT-licensed producer correction. The independent interpreter
parser, adapter and runtime continue to verify the explicit bare-loop form,
zero control operands, named transfers and loop back edges. Source regressions
exercise both single and nested same-line loops against GNU Fortran.

Release integration replays this patch after 0052 and 0053 against the exact
0.30 vendor tree. All 457 final vendor files match byte for byte with zero fuzz
and no offsets. The upstream pin and prior correction history are unchanged.
