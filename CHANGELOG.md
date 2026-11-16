# Changelog

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
