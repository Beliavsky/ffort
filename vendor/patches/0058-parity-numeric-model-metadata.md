# 0058: PARITY and numeric-model inquiry metadata

Local MIT-licensed FortFront corrections after0057. Apply at the vendor root
with `patch -p1 --fuzz=0`. This patch depends on0057's two additional registry
entries; the resulting count82 includes all three new PARITY/TINY/RADIX entries.
EPSILON and HUGE were already registered.

Register PARITY as a logical-array reduction and preserve scalar/no-DIM versus
rank-minus-one/DIM metadata, including keyword MASK/DIM. Register TINY and RADIX.
Resolve EPSILON/TINY/HUGE as scalar inquiries with the argument's type/kind and
RADIX as scalar default INTEGER. The independent interpreter guards enforce the
supported operand categories, ranks and kinds; no value evaluation is added to
these metadata queries. Source-level semantics remain in the interpreter.

The unchanged M_intrinsics PARITY, FLOOR, RADIX and TINY examples and focused
producer, adapter and runtime suites validate this bounded addition. This patch
does not add unsupported numerical kinds, descriptors, output formats or file I/O.
