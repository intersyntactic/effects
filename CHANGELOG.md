# Changelog

## 0.14.0

- `Request` is split in two, and the name is retired. `ProposedRequest`
  is what a tool or the model proposes: origin, method, path, sign-in,
  headers, body and what to keep, and no grant. `GrantedRequest` is one
  the airlock granted, made only by
  `GrantedRequest.under(proposed, grantedPathPrefix)`, which throws when
  the prefix doesn't cover the path; `grantedPathPrefix` is never null,
  and `/` grants the whole site. `CarriesOutWebRequests` takes a
  `GrantedRequest`. A nullable `Request.grantedPathPrefix` meant both
  "the grant bounds no path" and "nobody filled it in", so the airlock
  could hand the driver requests with it empty and the redirect bound
  never applied. Wire: `encodeProposedRequest`/`decodeProposedRequest`
  (a proposal carrying `grantedPathPrefix` is refused) and
  `encodeGrantedRequest`/`decodeGrantedRequest` (the proposed fields plus
  a required `grantedPathPrefix` covering the path). Breaking.

## 0.13.0

- `WebPath.parse` returns null unless the path is exactly what gets sent:
  parsing it after an origin must leave its path and query byte for byte
  as they are. This refuses escaped dot segments (`%2e%2e`, `.%2E`,
  `%2E.`, `./`), which a URI parser collapses, so `/a/%2e%2e/b` was
  sent as `/b`. Also refused: `%25` followed by `2e`, `2f`, `5c` or `25`
  in either case, which a server that decodes twice turns into `.`, `/`,
  `\` or another escape (any other `%25`, as in `50%25.docx`, is an
  ordinary `%`); lowercase escapes (`%2f`) and escaped
  unreserved characters (`%2E`), which a parser rewrites; and a
  fragment. A query is still allowed if it is left as it is.
  `Uri.encodeComponent` output passes. Breaking: a path that parsed
  before may now be null.
- `PathPrefix`: the start of the paths something may reach on an
  origin. `parse` returns null unless it starts and ends with `/`, has
  no `?`, is a valid `WebPath` and every segment is UTF-8; `/` alone is
  the whole site. `covers(WebPath)` is true when the path, without its
  query, has more segments than the prefix and starts with all of its
  segments, compared canonically (each decoded and encoded again with
  `Uri.encodeComponent`), so `19:` and `19%3A` match while a request is
  still sent as written. `==` is canonical too. Wire: the bare string,
  as written, via `encodePathPrefix`/`decodePathPrefix`.
- `AddressPrefix`: an `Origin` and a `PathPrefix`, such as a
  trajectory's reply endpoint or a fetch grant's bound.
  `covers(Origin, WebPath)`. Wire: `{"origin", "pathPrefix"}` via
  `encodeAddressPrefix`/`decodeAddressPrefix`.
- `Request.grantedPathPrefix`: the `PathPrefix` on the request's origin
  it was granted under, which must cover its path (the constructor
  throws `ArgumentError`, decoding a `FormatException`, otherwise).
  `CarriesOutWebRequests` says a redirect hop on the request's own
  origin that leaves it is `Refused`; a hop to another origin is the
  driver's to allow as before. Null bounds no path. Wire: written only
  when set, so every existing request decodes as before.
- `BuildsRequestsAnsweringEvents` is removed. The airlock no longer
  builds replies: a turn's final text goes to the conversation's reply
  tool, which builds and proposes its own requests. Breaking for its
  implementers and callers (teams_module and the airlock), both of
  which drop it in the move to this version.
- `ProgramName.parse` also refuses a `/`, a NUL, and `.` or `..` alone.
  A program is named, never located: `/bin/sh` and `../../x` parsed,
  and an executor runs a name holding `/` as that file. Breaking: a name
  that parsed before may now be null.
- `ListsInstalledPrograms.installedPrograms()`: the programs a
  `RunsPrograms` on this machine would find by name, so loop_launcher
  can check a trajectory's rules against the machine before it starts.
  Wire: `encodeProgramNames` writes a sorted list of names, so one set
  always encodes to the same bytes; `decodeProgramNames` refuses a
  non-list, an invalid name or a duplicate.

## 0.12.0

- `BuildsRequestsAnsweringEvents`: what a relay's module implements so
  the airlock can post back to where one of its events came from without
  knowing that relay's wire. `trajectoryOpenedRequests(relayedEvent:,
  signIn:)` builds the requests saying a trajectory opened for the event;
  `replyRequests(relayedEvent:, reply:, signIn:)` builds the requests
  that post a `ModelReply`, in posting order. Each is null when the event
  isn't one the module can answer. `relayedEvent` is the event's bytes as
  its relay recorded them, so is_effects needs no docking station type.
  The module only builds: the airlock decides each request and the web
  request driver sends it.
- `BotPool`: the name of a pool of bots a trajectory leases one from,
  shaped like `SignIn` (`parse` returns null unless it is lowercase
  letters, digits, `-` and `_`). Wire: the bare name, via
  `encodeBotPool`/`decodeBotPool`.

## 0.11.1

- `ReadsAndWritesFiles` and `CarriesOutWebRequests` say a text read
  keeps a leading byte order mark (U+FEFF). Dart's `utf8.decode` drops
  it, so a driver that decodes with it doesn't return the exact text,
  and reading then writing a file strips the BOM from disk. Doc only.

## 0.11.0

- `WebResponse` can carry a body. `Request.keep` (`BodyToKeep`: `none`,
  `text`, `bytes`; default `none`) says what of a 2xx response's body
  comes back, so the airlock decides on that along with the rest of the
  request. `WebResponse.body` is a `ResponseBody`: `NoBody`,
  `TextBody(String)` or `BytesBody(Uint8List)`.
- `CarriesOutWebRequests` documents the driver's rules: it caps the
  body's size and `Refused` anything over the cap; a text body that
  isn't UTF-8 is `Refused`; it never sends a sign-in's secret to another
  origin.
- `WebResponse.redirects`: a `List<RedirectedTo>`, every hop the driver
  followed, in order; empty when it followed none. Each `RedirectedTo`
  holds an http(s) address with its query, fragment and credentials
  dropped, so the token in a pre-authenticated download address never
  reaches the logbook. `RedirectedTo.of` drops
  those parts; `parse` refuses a recorded address that has any of them.
- The wire is additive: `keep`, `body` and `redirects` are written
  only when set, so every existing logbook entry decodes as before. Bytes go
  as base64.
- `ModelAndSignIn`: a `ModelName` and the `ModelSignInName` it is called
  under, such as a starting model. Wire: `{"signIn": ..., "model": ...}`
  via `encodeModelAndSignIn`/`decodeModelAndSignIn`.

## 0.10.0

- **Breaking:** `ReadsAndWritesFiles` gains `readBytes(path)`, returning
  `Outcome<BytesReadResult>`: `ReadBytes(Uint8List)` or `ReadMissing`.
  Every implementer must add it. The caller chooses text or bytes, so a
  text reader never has to handle bytes, and a bytes reader never has to
  handle text. `ReadMissing` is a case of both results.
- `read` documents what it does with a file that isn't UTF-8: `Refused`,
  never decoded loosely. `readBytes` documents its size cap: the driver
  sets it, and a file over the cap is `Refused`.
- `encodeBytesReadResult`/`decodeBytesReadResult`: bytes go on the wire
  as base64 under `{'kind': 'bytes', 'base64': ...}`.

## 0.9.0

- **Breaking:** `WebRequestOutcome` is now `WebResponse`: it holds the
  site's HTTP response (`status`, `created`, `refusedBecause`), nothing
  about the request or the airlock's own outcome, and the old name
  collided with `Outcome<O>`, which it isn't one of.
  `CarriesOutWebRequests.carryOutWebRequest` now returns
  `Outcome<WebResponse>`. `encodeWebRequestOutcome`/
  `decodeWebRequestOutcome` are now `encodeWebResponse`/
  `decodeWebResponse`; the JSON shape (`status`, `created`,
  `refusedBecause`, no type tag) is unchanged.
- **Breaking:** `ModelReply` is now a sealed class: `FinishedReply` (the
  model's whole text) or `CutOffReply` (the call ran and spent tokens,
  but the reply ended before the model was done — such as ChatGPT's own
  `incomplete` status). A cut-off reply is still recorded as `Ran`, never
  `Refused`, since tokens were spent and a reply did come back; the
  split exists so a switch over `ModelReply` has to say what it does
  with a cut-off one, rather than leave that to a flag a reader could
  forget to check. Any code built against the old concrete
  `ModelReply(text, ...)` needs updating to `FinishedReply(text: ...)`
  or `CutOffReply(text: ...)`.
- Both variants gain `usage` (a new `ModelUsage`: `input`, `cacheRead`,
  `output`, plus `cacheCreation` and `contextWindow`, both null when a
  driver can't report them). `ModelUsage.context` is
  `input + cacheRead + (cacheCreation ?? 0)` — never `output`, which
  leaves with the reply rather than staying in context. The wire stays
  additive where it can: `encodeModelReply` still writes a bare string
  for a `FinishedReply` with no usage, identical to every reply recorded
  before this version, and `decodeModelReply` still reads a bare string
  that way. Any other reply — usage set, or cut off — encodes as an
  object instead, which is breaking for a reader that matches the old
  bare-string shape directly rather than reading through
  `decodeModelReply`.

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
  `model`, or the driver refuses without calling, so the logbook can
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
  reaches the logbook instead of staying in the driver's own logs.
- Reworded `Request.body` and `Sent`'s doc comments: no body is kept
  because what a reader needs back is already elsewhere in the logbook,
  not because of a by-reference ruling (there is none).

## 0.1.0

- First release: the vocabulary of effects and the driver interfaces, moved
  out of `is_airlock_api` so a driver depends on effects alone.
  `PathInRepo`, `ProgramName`, `FileText`, `Args`, `ReadResult`, `Wrote`,
  `ExecResult` (`Exited`, `Killed`), `Outcome` (`Ran`, `Refused`),
  `Progress` (`Printed`), and `FileDriver`, `ProgramDriver`.
