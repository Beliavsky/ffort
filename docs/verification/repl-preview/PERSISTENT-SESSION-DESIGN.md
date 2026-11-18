# Persistent REPL session design: investigation, not implementation

## Decision for the initial increment

Ship a source buffer and explicit fresh `.run` first. Do not claim persistent variables, `.vars`, bare-expression queries or suffix execution. Never implement queries by replaying the entire accumulated program: this duplicates output, restarts or advances RNG incorrectly, rereads input and repeats procedure effects. A whole-buffer run is appropriate only when the user explicitly requests that operation.

This investigation made no runtime edits. It examined the isolated 0.57 worktree derived from delivered 0.56, plus `/tmp/ofort-main-repl.c` and `/tmp/test-ofort-repl.py`. References below describe that initial snapshot.

## Actual current execution lifecycle

`src/fi_runtime.f90`:

- `execute_program` (around lines 281–348) constructs or accepts a pointer context, increments the frame generation, marks the activation live, calls `execute_frame`, then marks it dead and nullifies the registered frame references on both success and error returns.
- `execute_frame` (around 549 onward) owns local `variables`, `arrays`, `initialized`, `active_variable` and `refs`. Around 706 it allocates these anew for each invocation, followed by declaration/storage initialization. Execution starts at `entry_pc` for a main program, or the procedure interval for a call.
- `array_storage_t` combines owned allocatable values/flags with pointer aliases `data`/`flags`, borrowed-view state and owner depth/symbol/generation metadata. Intrinsic assignment is not a safe general relocation operation for such storage.
- `module_store_t` is indexed by compiled symbol ID and initially allocated to `prog%ns`. Its retention alone does not retain main-program locals, and growth requires checked resizing/rebinding.
- Optional `random_state` and `input_units` can preserve those particular effects, but do not turn an invocation into a retained top-level activation.
- Pointer-context output column/tail state supports nonadvancing output and belongs to the execution lifecycle too.

The ofort reference explicitly extracts unexecuted source using `executed_len` in `execute_repl_pending_source` (around line 5853), executes it on an existing interpreter, and evaluates an expression on that retained interpreter (around 5906). It is not evidence that whole-source replay would provide equivalent behavior here.

## Viable bounded persistent API

A future opaque runtime session should own:

1. The compiled program revision and an executed-statement frontier.
2. Stable top-level scalar/array storage and definedness flags.
3. Module/SAVE storage where admitted, with once-only initialization.
4. RNG state, registered-input cursors and the output cursor/tail context.
5. A live top-level ownership epoch, invalidated only by explicit destruction/reset.

Factor execution into validation/initialization, execution of a complete top-level instruction interval, read-only inspection, and destruction. Rebuild references onto owned stable storage rather than copying descriptors that contain pointers. Keep expression caches, transient loop state and step accounting command-local. Yield only after completed statements/closed blocks with no live callees or active DO variables.

Normal procedure frames must retain their current generation enter/leave behavior. A persistent top-level frame needs a different lifecycle, not a global removal of frame retirement.

### First persistent subset

Freeze declarations and procedure/module definitions before first execution. Allow only append-only, complete executable statements or blocks afterward. Reject changes to existing declaration identity, type, kind, rank, bounds, CHARACTER length, storage attributes or initialization.

Reparsing the whole buffer for validation is acceptable; reexecuting its old prefix is not. Before suffix execution, compare the previous logical instruction prefix and its symbol/expression bindings. Numeric symbol IDs alone are not sufficient identity after a reparse. An initial implementation may conservatively reject any old-ID drift rather than implement remapping.

A long-term identity should include declaration origin and scope identity plus storage/type layout, not just a case-folded variable name. New declarations require an explicit storage-growth transaction and alias rebinding; defer that feature initially.

### Queries

`.vars` should inspect retained storage directly, preserving undefinedness, allocation state, shape and bounds. It must not run initializers or buffered statements.

Bare-expression queries should compile an ephemeral expression against session declarations and evaluate only that expression using retained storage. Initially admit a checked effect-free arithmetic/intrinsic subset; reject user calls and RNG/time/input effects. Printing query results is an explicit query effect, distinct from repeating earlier program output.

## Failure and editing semantics

- Parse/check failure: reject the candidate addition without changing runtime state or the committed execution frontier.
- Runtime failure: do not promise rollback. Output, input movement, RNG advancement and partial assignments may already have happened. Preserve the diagnostic and partial state, mark execution tainted and require explicit reset/fresh run before more execution. Never automatically retry a failed suffix.
- Editing before the executed frontier invalidates live state. Inspection should say that state is stale, not silently replay the program.
- `.run`: intentionally execute the entire current buffer as a fresh program, with freshly initialized RNG and fresh copies of registered-input starting positions under the documented driver policy.
- `.clear`: free state and clear the buffer. A separate `.reset`, if introduced, should explicitly distinguish retaining source from retaining values.
- STOP, step exhaustion and interrupted input require explicit terminal states rather than pretending a suffix completed successfully.

## Ownership hazards that need separate tests

Arrays and allocatables can move or reallocate storage. That can invalidate `refs`, pointer targets and borrowed views. Owner generations must not falsely certify stale pointers. Procedure argument value-result copyback, host associations, recursive frames, module/SAVE initialization, derived records and nonadvancing output all complicate persistence.

Do not bundle arbitrary pointer/procedure/module editing into the first persistent implementation. Whole-array state cloning is not a substitute for ownership-aware transactions, especially when aliased targets or records contain allocation state.

## Effort and release sequencing

- Buffer plus explicit fresh `.run`: a bounded driver/UI feature, independent of runtime persistence.
- Faithful scalar persistence: a material executor lifecycle refactor requiring a separate regression gate.
- Fixed arrays and allocatables: additional descriptor/ownership work after scalar lifecycle correctness.
- Arbitrary pointer, procedure and module evolution: high-risk follow-on work, not a cheap extension of the first REPL.

Essential discriminating tests include output and counters occurring once across queries, continuing RNG sequences, nonrepeated input reads, undefined values remaining undefined, failed effects never being duplicated, source-edit/reset invalidation, stable declaration identity, and rejection of queries before any valid retained state exists.
