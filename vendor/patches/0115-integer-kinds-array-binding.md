# 0115: scoped INTEGER_KINDS array data binding

Applies after frozen0114. Adds a distinct intrinsic-module array binding only for ISO_FORTRAN_ENV INTEGER_KINDS, respecting ONLY/renames, local and host ownership, NON_INTRINSIC and earlier source-module shadowing. An omitted-nature USE before a later same-named source module follows the interpreter existing source-order policy. Explicit INTRINSIC selects the intrinsic module regardless.

Independent type queries report default-INTEGER whole rank1, scalar element rank0, section/vector rank1; they do not encode any host processor values or claim small-kind arithmetic. The explicit-interface checker recognizes the scoped data binding, not a global name exemption. A separate fi_frontend adapter delta validates immutable import descriptors, exact owning USE/local/remote identity, occurrence metadata and unchanged subscript trees, without pretending the USE is a declaration node.

Independent source review passed: receipt iso-array-review-e4a17f32.json SHA e2ce9f85b0ae2f011498fcfc1d7811383dd8b5a9b44da5a0709c0c0c52bf604b. Focused candidate/native execution of this successor passed. First66 source observations, including the genuine indexed-import rejection and two generated overlong lines, remain immutable. Added continued-line variants and scope controls are separately named.

Focused final verification on immutable third-preview CLI1fdf604b: source 72 (40 success, 30 exact checking rejections, 2 exact runtime rejections), GNU 72 contracts, five native programs totaling 2971 assertions, and strict pure harness controls. Complete release aggregate is separate. See the focused evidence receipt for exact identities and preserved initial failures.
