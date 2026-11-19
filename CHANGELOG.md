# Changelog

## 0.9.0

- **Breaking:** `WebRequestOutcome` is now `WebResponse` (Nick, 2026-11-18):
  it holds the site's HTTP response (`status`, `created`,
  `refusedBecause`), nothing about the request or the airlock's own
  outcome, and the old name collided with `Outcome<O>`, which it isn't
  one of. `CarriesOutWebRequests.carryOutWebRequest` now returns
  `Outcome<WebResponse>`. `encodeWebRequestOutcome`/
  `decodeWebRequestOutcome` are now `encodeWebResponse`/
  `decodeWebResponse`; the JSON shape (`status`, `created`,
  `refusedBecause`, no type tag) is unchanged.
- `ModelReply` gains `usage` (a new `ModelUsage`: `input`, `cacheRead`,
  `output`, plus `cacheCreation` and `contextWindow`, both null when a
  driver can't report them) and `incomplete` (the call ran and spent
  tokens, but the reply was cut off before the model was done — such as
  ChatGPT's own `incomplete` status; still recorded as `Ran`, never
  `Refused`, since tokens were spent and a reply did come back).
  `ModelUsage.context` is `input + cacheRead + (cacheCreation ?? 0)` —
  never `output`, which leaves with the reply rather than staying in
  context — matching how the monorepo's `intersyntactic_protocol`
  already counts it (agent_loop, 2026-11-19). Additive and non-breaking:
  both new fields are optional, and `encodeModelReply` still writes a
  bare string when neither is set, identical to every reply recorded
  before this version; `decodeModelReply` still reads a bare string as
  a reply with no usage. Once a reply does carry `usage` or
  `incomplete`, it encodes as an object instead — breaking for a reader
  that matches the old bare-string shape directly, such as
  `is_airlock_api`'s plain-message projection (flagged to
  airlock-api-b3, who confirmed it reads replies through
  `decodeModelReply` rather than matching the shape itself).

## 0.8.0

- **Breaking:** `ProgramMessage` (and its two cases, `Reported` and
  `Finished`) now takes a type parameter for the outcome: `Finished<O>`
  carries an `Outcome<O>`, the same way `encodeOutcome`/`decodeOutcome`
  already took an output codec. `encodeProgramMessage`/
  `decodeProgramMessage` each take that codec too. This is a Dart-types-
  only change — the JSON bytes for `ProgramMessage<ExecResult>` are
  unchanged (pinned by a golden-bytes test against lines captured from
  the deployed `program_driver` socket, infra-5e) — but it is still
  source-breaking for any exhaustive switch or decode call written
  against the old non-generic types. A driver can now carry
  `Finished<ModelReply>` down the same wire a `RunsPrograms` driver
  already used for `Finished<ExecResult>`, instead of hand-rolling its
  own envelope (claude_code_driver did exactly that, flagged by
  web-driver-0b).
- New, purely additive: `encodeModelCall`/`decodeModelCall`, a codec for
  the `{signIn, model, systemPrompt, request}` envelope a caller sends
  an `AsksTheModel` service, agreed field-for-field with
  claude-code-driver-9f so the airlock and a model driver can't
  disagree on the shape. `systemPrompt` and `request` pass through
  byte-exact — no trimming or normalising. `decodeModelCall` throws
  `FormatException`, never another exception type, on anything it
  can't read, since a service on the other end treats that one type as
  "refuse the call" and anything else as a crash.

## 0.7.0

- **Breaking:** `Progress` gains `ReplyArriving`, a piece of the model's
  reply as it streams, never recorded. A new sealed-class case is
  breaking for any exhaustive switch over `Progress` outside this
  package.
- The model call is now an action, reversing the 2026-11-12 ruling that
  it stayed on the agent's side: the loop that proposes a call holds no
  model sign-in and reaches the model only through a driver (RULINGS.md,
  "the model call goes through the airlock"). New, purely additive:
  `ModelSignInName` (a model sign-in by name, never the secret, built
  like `SignIn`), `ModelName` (a model id, a checked string), `ModelReply`
  (the model's final text, kept whole, recorded once as an outcome), and
  `AsksTheModel`, named for what it does: holds every model sign-in, so
  `askTheModel(signIn, model, systemPrompt, request, {required report})`
  is the only way off this machine for a model call. `systemPrompt` and
  `request` are each the exact bytes the airlock approved, verbatim —
  found during review (web-driver-0b, against a driver whose system
  prompt is a separate CLI argument, not part of one request body) that
  a single `request` string had nowhere for it. `AsksTheModel`'s doc is
  now also a contract: when `request` itself names a model, it must be
  `model`, or the driver refuses without calling, so the record can
  never show one model decided and another called (airlock-api-04).

## 0.6.0

- **Breaking:** `encodeStart`/`decodeStart` are now
  `encodeProgramToRun`/`decodeProgramToRun`; the error-label default
  `'start'` is now `'programToRun'`. Flagged after 0.5.0 retired
  `StartsPrograms`/`start` as fossil words still naming this codec pair
  and its own error messages. `ProgramToRun` over `RunProgram`: this
  encodes data (the program and its args), not an instruction. No JSON
  key changes — `'start'` was only ever the error-message field label —
  so this needs no coordinated redeploy. No deprecated alias kept.

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
