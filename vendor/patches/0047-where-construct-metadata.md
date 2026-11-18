# 0047: Complete bounded WHERE metadata

Local MIT-licensed FortFront corrections:

- Register WHERE in the existing fallback parser dispatch, allowing nested
  IF/DO/SELECT statement bodies without introducing module dependency cycles.
- Route procedure-body WHERE through the complete WHERE parser and scan its
  complete statement/construct interval instead of dropping its header/body.
- Recognize ENDWHERE alongside END WHERE.
- Preserve physical source locations for WHERE assignments after continued
  headers. The common statement-body helper has an optional location flag;
  only WHERE callers request it, leaving other construct parsing unchanged.

No semantic validation is disabled. The interpreter adapter independently
validates masks, assignment identity/order, arm links, final targets and scope.
Native adapter/runtime corruption tests and GNU differential programs cover
both statement and construct forms in main and procedure/nested contexts.

Apply after patch 0046 using `patch -p1` at the vendored FortFront root.
