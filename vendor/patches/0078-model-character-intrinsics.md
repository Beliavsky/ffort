# 0078: DIGITS, NEW_LINE and RRSPACING metadata

Local MIT-licensed producer extension after cumulative patch 0077.
Adds three unique registry names (107 to 110), default INTEGER scalar DIGITS,
default CHARACTER scalar NEW_LINE and same-kind elemental REAL RRSPACING.
NEW_LINE uses the standard A keyword; adapter keyword/source identity validation
is independent of producer metadata. No wide CHARACTER or REAL16 support is implied.

Apply using `patch --fuzz=0 -p1` from the cumulative vendor root after 0077. The feature
core already contains the raw source delta; do not apply both copies.
