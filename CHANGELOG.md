# Changelog

## 0.5.0

- **Breaking:** `StartsPrograms` is now `RunsPrograms`; its `start` is now
  `runProgram`. Nick's ruling: `start` named one of five steps (feed
  stdin, stream through `report`, enforce the time limit, return only on
  exit or kill); `run` covers all of it. `CarriesOutActions` and
  `ReadsAndWritesFiles` from 0.4.0 stand as they are. No deprecated alias
  kept.

## 0.4.0

- **Breaking:** the four driver interfaces are named for what they can
  do, not as a thing — Nick's ruling, after `implements WebDriver` read
  as "WebDriver is an api?": `Driver` → `CarriesOutActions`, `FileDriver`
  → `ReadsAndWritesFiles`, `ProgramDriver` → `StartsPrograms`,
  `WebDriver` → `CarriesOutWebRequests`. No deprecated alias kept.

## 0.3.0

- **Breaking:** `WebDriver.send` is now `carryOutWebRequest`; `Sent` is
  now `WebRequestOutcome`. Nick ruled out tiny words for complex things
  on 16 Nov (`send` and `renderer` named as examples): "longer names are
  ok". No deprecated alias kept, so the old word doesn't survive through
  the types every session reads.

## 0.2.3

- Depends on `is_path_confinement` so `FileDriver`'s doc comment can point
  at `isInsideTree` concretely, instead of describing confinement only in
  prose. Purely additive: `FileDriver` is still just an interface, no
  behaviour changes.

## 0.2.2

- `ProgramMessage`: what a program driver sends back about one run,
  `Reported(Progress)` while it is underway, then one `Finished(Outcome<ExecResult>)`.
  `Progress` is unchanged.
- Codecs for a program run across a wire: `encodeStart`/`decodeStart`
  (what `ProgramDriver.start` is given), `encodeProgress`/`decodeProgress`
  and `encodeProgramMessage`/`decodeProgramMessage`. For the airlock ↔
  program driver service. Purely additive.
- Fixed `RelativePath.folder` on a path made entirely of `..` segments
  (e.g. `RelativePath('..')`): it was returning root instead of one level
  further up again. Shipped broken since 0.1.0, but unreachable until the
  rename let an escaping path be constructed at all; no known caller hits
  it, fixed now to close the gap before one does.

## 0.2.1

- JSON codecs for every type: `RelativePath`, `FileText`, `ProgramName`,
  `Args`, `ReadResult`, `Wrote`, `ExecResult`, `Origin`, `Method`,
  `WebPath`, `SignIn`, headers, `Request`, `Sent`, `Outcome<O>`. Encode
  to a plain JSON value; decode re-runs the type's own validation and
  throws `FormatException` on bad input. For the agent loop ↔ airlock
  and airlock ↔ driver wire (`is_airlock_api` 0.5.0's `Carry`). Purely
  additive, no breaking changes.
- `isCredentialHeader` exported alongside `validatedHeaders`, so a
  caller that needs to check a header without catching `ArgumentError`
  (an `Error`, never caught by this repo's own convention) can.

## 0.2.0

- **Breaking:** `Request.path` is now a `WebPath`, not a plain `String`.
  `WebPath.parse` refuses anything without a leading `/`, a `//`
  authority, a `..` segment, or an `@` — ways a path could make a request
  reach somewhere other than the origin it was decided for. `WebPath.root`
  replaces the old default of `''`.
- Pulled the credential-header check out of `Request`'s constructor into
  an exported `validatedHeaders`, so `is_airlock_api`'s `Post` can apply
  the same guarantee to its own headers instead of re-declaring the
  forbidden-header list.
- From issue #1147's design discussion (`enspyrco/intersyntactic#1147`):
  `WebPath` is web-driver-0b's finding, `validatedHeaders` is shared with
  effects-98's.

## 0.1.3

- Genericize destination examples in `web.dart`'s doc comments
  (`smba.trafficmanager.net`, `hart-bot`): a shared vocabulary shouldn't
  carry one consumer's deployment details in its examples.

## 0.1.2

- Fix `refusedBecause`'s doc comment: a refused sign-in (an AADSTS code,
  nothing sent) is `Refused`, not `Sent.refusedBecause`, which is only
  for a destination's own refusal of something that did go out.

## 0.1.1

- `Sent` gains `refusedBecause`, the destination's own reason for a
  non-2xx reply (a Teams 400 body, an AADSTS code), so a failure's why
  reaches the record instead of staying in the driver's own logs.
- Reworded `Request.body` and `Sent`'s doc comments: no body is kept
  because what a reader needs back is already elsewhere in the record,
  not because of a by-reference ruling (there is none).

## 0.1.0

- First release: the vocabulary of effects and the driver interfaces, moved
  out of `is_airlock_api` so a driver depends on effects alone.
  `PathInRepo`, `ProgramName`, `FileText`, `Args`, `ReadResult`, `Wrote`,
  `ExecResult` (`Exited`, `Killed`), `Outcome` (`Ran`, `Refused`),
  `Progress` (`Printed`), and `FileDriver`, `ProgramDriver`.
