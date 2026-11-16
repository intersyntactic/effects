# is_effects

The shared vocabulary of intersyntactic's effects: what a tool's run
describes, the airlock decides on, and a driver carries out.

A driver depends on this package alone, so it sees no run, journey path or
decision: it is reached only once a run is decided, by `is_airlock_api`.

## What an effect takes and gives back

- `RelativePath`: a path relative to a driver's root, normalised by its
  constructor. Whether it may leave that root — by its text, or by a
  symlink only the disk can show — is the operator's choice, enforced by
  the driver.
- Reading and writing: `FileText` in, `ReadResult` (`ReadText`,
  `ReadMissing`) and `Wrote` out.
- Starting a program: a `ProgramName` (made only by `parse`, no whitespace)
  and `Args`, giving an `ExecResult`, which is `Exited(exitCode)` or
  `Killed(why)`, each with stdout and stderr. How long a program may run,
  and when it is killed, is the driver's.
- Reaching the world: an `Origin` (scheme, host and port only), a
  `WebPath` (made only by `parse`: a leading `/`, no authority, no `..`
  or `@`, so a path can never name somewhere other than where it was
  decided to go) and an optional `SignIn` by name, with a `Request` — the
  web driver's input: method, path, headers (`validatedHeaders`, which
  refuses a credential) and an optional body — giving `Sent` (`status`,
  and either `created` or, for a non-2xx reply, `refusedBecause`).
- `Outcome<O>`: `Ran(output)`, or `Refused(why)`.
- `Progress`: what a driver reports while it works, `Printed` for a
  program's output.

A journey path's prompts are made by its own loop, which holds only the
sign-ins its rules allow, not through an effect here.

## Drivers

`FileDriver`, `ProgramDriver` (reporting progress as it goes) and
`WebDriver`. A machine loads the drivers it can run: a phone's loads no
`ProgramDriver`.

The library imports `path` and nothing else outside the SDK; a test reads
every directive's URI from Dart's parse tree and holds it to that.
