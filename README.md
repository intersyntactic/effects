# is_effects

The shared vocabulary of intersyntactic's actions: what a tool's action
describes, the airlock decides on, and a driver carries out.

A driver is given only the action's program and input; the trajectory,
the decision and what follows stay with `is_airlock_api`.

## What an action takes and gives back

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
  decided to go) and an optional `SignIn` by name, with a
  `ProposedRequest` (method, path, headers by `validatedHeaders`, which
  refuses a credential, and an optional body), which the airlock decides.
  A `GrantedRequest` is one it granted under a `PathPrefix`: the web
  driver's input, giving a `WebResponse`
  (`status`, and either `created` or, for a non-2xx reply,
  `refusedBecause`).
- Calling the model: a `ModelSignInName` by name (never the secret) and a
  `ModelName` (a model id, such as `claude-opus-5-5`), with the exact
  system prompt and request the airlock approved, giving a `ModelReply`:
  `FinishedReply` (the model's whole text) or `CutOffReply` (the call ran
  and spent tokens, but the reply ended before the model was done) —
  a closed set, so a caller can't treat a cut-off answer as the model's
  full word just because it forgot to check. Both carry `usage` (a
  `ModelUsage`, null when the driver can't report one).
- `Outcome<O>`, split on whether the world changed: `Ran(output)`;
  `NothingRan(why)`, where nothing happened (a deny, no driver, bad
  input); or `StoppedPartway(why, done)`, never safe to retry, where
  `done` is the action's own output for what had already happened (the
  responses to the requests already sent), or null when that isn't
  known. An outcome recorded as `refused` before the split reads back as
  `StoppedPartway` with `done` null.
- `Progress`: what a driver reports while it works, `Printed` for a
  program's output, `ReplyArriving` for a piece of the model's reply as
  it streams — never recorded; only the whole `ModelReply` is.

A trajectory's prompts are made by its own loop, which holds no model
sign-in and reaches the model only through `AsksTheModel`, never
directly — the model is outside the station.

## Drivers

`ReadsAndWritesFiles`, `RunsPrograms` (reporting progress as it goes),
`CarriesOutWebRequests` and `AsksTheModel`. A machine loads the drivers
it can run: a phone's loads no `RunsPrograms`.

The library imports only `path` and `is_path_confinement` outside the SDK;
a test reads every directive's URI from Dart's parse tree and holds it to
that.
