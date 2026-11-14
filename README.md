# is_effects

The shared vocabulary of intersyntactic's effects. Tools describe effects in
these words, the airlock decides on them, and drivers carry them out.

A driver depends on this package alone, so it sees no run, journey path or
decision: it is reached only once a run is decided, by `is_airlock_api`.

## What an effect takes and gives back

- `PathInRepo`: a path inside the repo, made only by `parse`. What stays
  inside is the text; a symlink in the tree can still point out, and only a
  driver can refuse that.
- Reading and writing: `FileText` in, `ReadResult` (`ReadText`,
  `ReadMissing`) and `Wrote` out.
- Starting a program: a `ProgramName` (made only by `parse`, no whitespace)
  and `Args`, giving an `ExecResult`, which is `Exited(exitCode)` or
  `Killed(why)`, each with stdout and stderr. How long a program may run,
  and when it is killed, is the driver's.
- `Outcome<O>`: `Ran(output)`, or `Refused(why)`.
- `Progress`: what a driver reports while it works, `Printed` for a
  program's output.

Nothing here sends out of the home. A journey path's model calls are made by
its own loop, which holds only the sign-ins its rules allow; an effect for a
tool that sends is added when a tool needs one.

## Drivers

`FileDriver` and `ProgramDriver`, the latter reporting progress as it goes.
A machine loads the drivers it can run: a phone's loads no `ProgramDriver`.

The library imports `path` and nothing else outside the SDK; a test reads
every directive's URI from Dart's parse tree and holds it to that.
