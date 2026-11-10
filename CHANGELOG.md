# Changelog

## 0.1.0

- First release: the vocabulary of effects and the driver interfaces, moved
  out of `is_airlock_api` so a driver depends on effects alone.
  `PathInRepo`, `ProgramName`, `FileText`, `Args`, `ReadResult`, `Wrote`,
  `ExecResult` (`Exited`, `Killed`), `Request`, `Response`, `Destination`
  (`ProviderApi`, `SelfRunModel`, `Web`), `Provider`, `SignIn`, `Method`,
  `Outcome` (`Ran`, `Refused`), `Progress` (`Printed`, `Received`), and
  `FileDriver`, `ProgramDriver`, `NetworkDriver`.
