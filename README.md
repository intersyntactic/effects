# is_effects (discontinued)

`is_effects` held the types of every action at once: files, programs, web
requests, the model, and what each gives back. So a change to any one of
them made every package that depended on it move and release together.
It is now broken up into one vocabulary per action, and this last release
holds nothing.

Depend on the vocabularies directly. The JSON of every type is the same as
before, so anything already recorded or sent still reads back.

## Where each type went

| Was in `is_effects` | Now in |
|---|---|
| `Outcome`, `Ran`, `NothingRan`, `StoppedPartway`, `encodeOutcome` / `decodeOutcome` | [`is_outcome_vocabulary`](https://pub.dev/packages/is_outcome_vocabulary) ^0.1.0 |
| `ProgramMessage<O>`, `Reported`, `Finished` | `is_outcome_vocabulary`, as `ProgramMessage<P, O>` (see below) |
| `RelativePath` and its codec | [`is_relative_path_vocabulary`](https://pub.dev/packages/is_relative_path_vocabulary) ^0.1.0 |
| `FileText`, `FileRequest`, `ReadResult`, `BytesReadResult`, `Wrote`, `ReadsAndWritesFiles` | [`is_file_request_vocabulary`](https://pub.dev/packages/is_file_request_vocabulary) ^0.1.0 |
| `ProgramName`, `Args`, `ProgramRequest`, `ExecResult`, `RunsPrograms`, `ListsInstalledPrograms`, the `ProgramToRun` codec | [`is_program_request_vocabulary`](https://pub.dev/packages/is_program_request_vocabulary) ^0.1.0 |
| `Printed`, `Channel` (were cases of `Progress`) | `is_program_request_vocabulary`, with `encodePrinted` / `decodePrinted` |
| `Method`, `ProposedRequest`, `GrantedRequest`, `BodyToKeep`, `ResponseBody`, `RedirectedTo`, `WebResponse`, `validatedHeaders`, `CarriesOutWebRequests` | [`is_web_request_vocabulary`](https://pub.dev/packages/is_web_request_vocabulary) ^0.1.0 |
| `ModelName`, `ModelSignInName`, `ModelAndSignIn`, the `ModelCall` envelope, `AsksTheModel` | [`is_model_vocabulary`](https://pub.dev/packages/is_model_vocabulary) ^0.5.0 (see below) |
| `ReplyArriving` (was a case of `Progress`) | `is_model_vocabulary` ^0.5.0 |
| `BotPool` and its codec | [`is_sign_in_vocabulary`](https://pub.dev/packages/is_sign_in_vocabulary) ^0.1.2, from `package:is_sign_in_vocabulary/bot_pool.dart` |
| `CarriesOutActions` | gone (see below) |

## What changed shape

**Progress is split by action.** `Progress` put a program's `Printed` line
and a model's `ReplyArriving` piece in one sealed class, so a model driver
could report a printed line. Each now lives with its own action, and
`Report` is gone:

- `RunsPrograms.runProgram` takes `required void Function(Printed printed) report`.
- `AsksTheModel.askTheModel` takes `required void Function(ReplyArriving piece) report`.
- `encodeProgress` / `decodeProgress` are gone. Use `encodePrinted` /
  `decodePrinted`, or `ReplyArriving`'s `toJson` / `fromJson`. Each keeps
  the `kind` it had, so a deployed driver's lines read the same.

**`ProgramMessage` is generic over the report too:** `ProgramMessage<P, O>`.
`encodeProgramMessage(message, encodeProgress, encodeOutput)` and
`decodeProgramMessage(json, decodeProgress, decodeOutput)` take the
report's codec as well as the output's. A program driver's answer is
`ProgramMessage<Printed, ExecResult>`; a model call's is
`ProgramMessage<ReplyArriving, ModelReply>`.

**The model types use `toJson` / `fromJson`**, as the rest of
`is_model_vocabulary` does, and their decoders are strict:

| Was | Now |
|---|---|
| `encodeModelCall(signIn, model, systemPrompt, request)` | `ModelCall(signIn:, model:, systemPrompt:, request:).toJson()` |
| `decodeModelCall(json)`, a four-field record | `ModelCall.fromJson(json)`, a class; refuses an unknown key |
| `encodeModelAndSignIn` / `decodeModelAndSignIn` | `toJson()` / `ModelAndSignIn.fromJson` |
| `encodeModelSignInName(n)` / `encodeModelName(m)` | `n.name` / `m.value` |
| `decodeModelSignInName` / `decodeModelName` | `ModelSignInName.parse` / `ModelName.parse`, null when invalid |
| `encodeModelUsage` / `encodeModelReply` and their decoders | `toJson()` / `ModelUsage.fromJson` / `ModelReply.fromJson` |

`ModelCall.fromJson` refuses a key it doesn't know, so if the envelope
ever gains a field, deploy the model drivers before the airlock.

`is_model_vocabulary` 0.5.0 also adds a fifth `ModelTurn` case,
`NamedToolsDefined`, and `ModelRequest.namedTools`, so an exhaustive
switch over `ModelTurn` won't compile until it handles them. A driver that
can't offer named tools should refuse such a request (`NothingRan`), not
drop them: dropping them would hide tools from the model. Its refusal
messages are worded differently too (`signIn` is not a string, rather than
`modelCall.signIn: not a string`), which matters to anything that matches
the text.

**`CarriesOutActions` is gone.** It was an empty marker that only the
airlock used, to pick a driver out of a list by its type. In its place,
take one optional slot per kind of driver, such as
`({ReadsAndWritesFiles? files, RunsPrograms? programs, CarriesOutWebRequests? web, AsksTheModel? model})`,
so two drivers of one kind can't be handed over and one silently ignored.
