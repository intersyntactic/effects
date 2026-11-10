# is_effects

The shared vocabulary of intersyntactic's effects. Tools describe effects in
these words, the airlock decides on them, and drivers carry them out.

A driver depends on this package alone, so it sees no run, journey path or
decision: it is reached only once those are settled, by `is_airlock_api`.

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
- Sending out of the home: a `Request` to a `Destination`, giving a
  `Response`. A destination names what is on the other end:
  `ProviderApi(provider, signIn)`, `SelfRunModel.parse(address)`, or
  `Web.parse(site)`, the site alone. A `SignIn` is a name; its secret is the
  network driver's, and a request whose headers name a credential is an
  `ArgumentError`. `Args.leavesTo` is where a started program says it will
  send.
- `Outcome<O>`: `Ran(output)`, or `Refused(why)`.
- `Progress`: what a driver reports while it works, `Printed` for a
  program's output and `Received` for what arrives from a send.

Names and destinations compare by value, so a rule matches an effect with
`==`.

## Drivers

`FileDriver`, `ProgramDriver` and `NetworkDriver`, each reporting progress as
it goes. A machine loads the drivers it can run: a phone's loads no
`ProgramDriver`.

The library imports `path` and nothing else outside the SDK; a test reads
every directive's URI from Dart's parse tree and holds it to that.
