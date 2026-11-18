# Release 0.51.0: bounded DO WHILE

This checkpoint fixes the reported DO WHILE program without rewriting its source. Conditions are scalar default LOGICAL and are evaluated again at each header entry, including after CYCLE. Named transfers compose with counted/bare loops and SELECT CASE under the existing shared step budget.

Producer repairs distinguish a counted variable named WHILE, preserve named/nested implicit-main loop boundaries, and retain complete SELECT bodies inside WHILE. Independent runtime metadata/cache checks reject malformed conditions before evaluating them. The existing counted/bare loop behavior and resource limits remain.

A fresh empty-cache Linux/GNU build passed the complete maintained verifier: 11,104 source outcomes, 268 native programs and 2,342 unittest methods, with no failures. Seven static/shared comparisons and 10,566 custom integer-mask assertions are separately recorded. See [VERIFICATION.md](VERIFICATION.md) for evidence and category distinctions.

The standalone M_intrinsics 0.51 survey was not rerun after workspace loss; 0.50 survey reports are historical. Full utilities execution is still unsupported: the original resource boundary and adapted CHARACTER-gather boundary remain. CHARACTER gather and other next-feature drafts are not included.
