# Changelog

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
