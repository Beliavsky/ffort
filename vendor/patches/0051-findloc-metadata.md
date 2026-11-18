# 0051: FINDLOC registration and result metadata

Local MIT-licensed FortFront correction. Register FINDLOC as an intrinsic array
function and infer INTEGER result type, KIND and rank independently of ARRAY's
intrinsic type. VALUE is the required second argument, so the optional DIM and
KIND positional offsets differ from MINLOC/MAXLOC. Named arguments retain their
normal slots. The array semantic classifier and parameter scanner recognize the
same intrinsic identity.

No strict semantic validation is disabled. The interpreter adapter independently
checks actual association, ARRAY/VALUE types, VALUE rank, MASK shape, result
rank/type/KIND and intrinsic slot bits. Runtime checks remain separate and are
exercised through malformed public IR, including CHARACTER-kind corruption and
unevaluated KIND inquiries.

Originally developed against 0.28 through patch 0048, this release patch was regenerated against the exact final 0.29 vendor tree after patches 0049 and 0050. Its semantic delta remains exactly four files. Run `patch --fuzz=0 -p1` at the vendor root; replay reproduces all 457 vendor files byte for byte.
