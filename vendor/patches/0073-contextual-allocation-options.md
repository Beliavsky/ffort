# 0073: Contextual allocation option names

## Purpose

FortFront previously treated STAT, ERRMSG, SOURCE and MOLD as allocation options
from their spelling alone, even when the identifier named an allocatable object.
The bounded interpreter rejects ambiguous producer metadata, so these otherwise
valid declarations could not execute.

## Change

In parser_memory_statements.f90, bounded lookahead recognizes an option only when
the following token is '='. The parser position is restored before ordinary
object or option parsing. This applies independently to ALLOCATE and DEALLOCATE.
No registry, type metadata, execution or unsupported-option support is added.

## Replay

Apply this patch with -p1 at vendor/fortfront after 0072. Only the memory-statement
parser changes. It also applies to the frozen 0.39 vendor base because 0070–0072
do not modify this file. The project-root delivery includes this ledger and the
source delta; do not apply both source variants.

## Validation

Focused source cases use STAT alone and STAT/ERRMSG/SOURCE/MOLD together as object
names, with a genuine trailing STAT= control. They check and execute against GNU.
Multi-object native/source regressions and all existing native programs pass.
Unsupported SOURCE/MOLD/ERRMSG options still reject. The original source and MIT
license remain in the vendored tree.
