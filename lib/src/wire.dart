import 'dart:convert';
import 'dart:typed_data';

import 'bot_pool.dart';
import 'file.dart';
import 'model.dart';
import 'outcome.dart';
import 'program.dart';
import 'relative_path.dart';
import 'web.dart';

/// [json] as a `Map<String, Object?>`, or a [FormatException] naming
/// [field].
Map<String, Object?> _object(Object? json, String field) => switch (json) {
  final Map<String, Object?> map => map,
  _ => throw FormatException('$field: not an object'),
};

/// [json] as a [String], or a [FormatException] naming [field].
String _string(Object? json, String field) => switch (json) {
  final String s => s,
  _ => throw FormatException('$field: not a string'),
};

/// [json] as base64-decoded bytes, or a [FormatException] naming [field].
Uint8List _base64(Object? json, String field) {
  final raw = _string(json, field);
  try {
    return base64Decode(raw);
  } on FormatException {
    throw FormatException('$field: not base64');
  }
}

/// [json] as an [int], or a [FormatException] naming [field].
int _int(Object? json, String field) => switch (json) {
  final int n => n,
  _ => throw FormatException('$field: not an int'),
};

/// [json] as a [bool], or a [FormatException] naming [field].
bool _bool(Object? json, String field) => switch (json) {
  final bool b => b,
  _ => throw FormatException('$field: not a bool'),
};

// RelativePath

Object? encodeRelativePath(RelativePath path) => path.value;

RelativePath decodeRelativePath(Object? json, [String field = 'path']) =>
    RelativePath(_string(json, field));

// FileText

Object? encodeFileText(FileText file) => {
  'path': encodeRelativePath(file.path),
  'text': file.text,
};

FileText decodeFileText(Object? json, [String field = 'file']) {
  final map = _object(json, field);
  return FileText(
    decodeRelativePath(map['path'], '$field.path'),
    _string(map['text'], '$field.text'),
  );
}

// ProgramName

Object? encodeProgramName(ProgramName name) => name.value;

ProgramName decodeProgramName(Object? json, [String field = 'program']) {
  final raw = _string(json, field);
  return ProgramName.parse(raw) ??
      (throw FormatException('$field: not a program name ($raw)'));
}

// Args

Object? encodeArgs(Args args) => {
  'args': args.args,
  'stdin': args.stdin,
  'inFolder': encodeRelativePath(args.inFolder),
};

Args decodeArgs(Object? json, [String field = 'args']) {
  final map = _object(json, field);
  final rawArgs = switch (map['args']) {
    final List<Object?> list => list,
    _ => throw FormatException('$field.args: not a list'),
  };
  return Args(
    [for (final (i, a) in rawArgs.indexed) _string(a, '$field.args[$i]')],
    stdin: switch (map['stdin']) {
      null => null,
      final String s => s,
      _ => throw FormatException('$field.stdin: not a string'),
    },
    inFolder: map.containsKey('inFolder')
        ? decodeRelativePath(map['inFolder'], '$field.inFolder')
        : RelativePath.root,
  );
}

// ReadResult

Object? encodeReadResult(ReadResult result) => switch (result) {
  ReadText(:final text) => {'kind': 'text', 'text': text},
  ReadMissing() => {'kind': 'missing'},
};

ReadResult decodeReadResult(Object? json, [String field = 'readResult']) {
  final map = _object(json, field);
  // wire-ok: this is the wire; decodeX pairs with encodeX below
  return switch (map['kind']) {
    'text' => ReadText(_string(map['text'], '$field.text')),
    'missing' => const ReadMissing(),
    final other => throw FormatException(
      '$field.kind: not "text" or "missing" ($other)',
    ),
  };
}

// BytesReadResult

Object? encodeBytesReadResult(BytesReadResult result) => switch (result) {
  ReadBytes(:final bytes) => {'kind': 'bytes', 'base64': base64Encode(bytes)},
  ReadMissing() => {'kind': 'missing'},
};

BytesReadResult decodeBytesReadResult(
  Object? json, [
  String field = 'bytesReadResult',
]) {
  final map = _object(json, field);
  // wire-ok: this is the wire; decodeX pairs with encodeX above
  return switch (map['kind']) {
    'bytes' => ReadBytes(_base64(map['base64'], '$field.base64')),
    'missing' => const ReadMissing(),
    final other => throw FormatException(
      '$field.kind: not "bytes" or "missing" ($other)',
    ),
  };
}

// Wrote

Object? encodeWrote(Wrote wrote) => {'replaced': wrote.replaced};

Wrote decodeWrote(Object? json, [String field = 'wrote']) {
  final map = _object(json, field);
  return Wrote(replaced: _bool(map['replaced'], '$field.replaced'));
}

// ExecResult

Object? encodeExecResult(ExecResult result) => switch (result) {
  Exited(:final exitCode, :final stdout, :final stderr) => {
    'kind': 'exited',
    'exitCode': exitCode,
    'stdout': stdout,
    'stderr': stderr,
  },
  Killed(:final why, :final stdout, :final stderr) => {
    'kind': 'killed',
    'why': why,
    'stdout': stdout,
    'stderr': stderr,
  },
};

ExecResult decodeExecResult(Object? json, [String field = 'execResult']) {
  final map = _object(json, field);
  final stdout = _string(map['stdout'], '$field.stdout');
  final stderr = _string(map['stderr'], '$field.stderr');
  // wire-ok: this is the wire; decodeX pairs with encodeX above
  return switch (map['kind']) {
    'exited' => Exited(
      _int(map['exitCode'], '$field.exitCode'),
      stdout: stdout,
      stderr: stderr,
    ),
    'killed' => Killed(
      _string(map['why'], '$field.why'),
      stdout: stdout,
      stderr: stderr,
    ),
    final other => throw FormatException(
      '$field.kind: not "exited" or "killed" ($other)',
    ),
  };
}

// ProgramToRun: what RunsPrograms.runProgram is given

Object? encodeProgramToRun(ProgramName program, Args args) => {
  'program': encodeProgramName(program),
  'args': encodeArgs(args),
};

(ProgramName, Args) decodeProgramToRun(
  Object? json, [
  String field = 'programToRun',
]) {
  final map = _object(json, field);
  return (
    decodeProgramName(map['program'], '$field.program'),
    decodeArgs(map['args'], '$field.args'),
  );
}

// Progress

Object? encodeProgress(Progress progress) => switch (progress) {
  Printed(:final channel, :final text) => {
    'kind': 'printed',
    'channel': channel.name,
    'text': text,
  },
  ReplyArriving(:final text) => {'kind': 'replyArriving', 'text': text},
};

Progress decodeProgress(Object? json, [String field = 'progress']) {
  final map = _object(json, field);
  // wire-ok: this is the wire; decodeX pairs with encodeX above
  return switch (map['kind']) {
    // wire-ok: this is the wire; decodeX pairs with encodeX above
    'printed' => Printed(switch (map['channel']) {
      'stdout' => Channel.stdout,
      'stderr' => Channel.stderr,
      final other => throw FormatException(
        '$field.channel: not "stdout" or "stderr" ($other)',
      ),
    }, _string(map['text'], '$field.text')),
    'replyArriving' => ReplyArriving(_string(map['text'], '$field.text')),
    final other => throw FormatException(
      '$field.kind: not "printed" or "replyArriving" ($other)',
    ),
  };
}

// ProgramMessage<O>

Object? encodeProgramMessage<O>(
  ProgramMessage<O> message,
  Object? Function(O output) encodeOutput,
) => switch (message) {
  Reported(:final progress) => {
    'kind': 'reported',
    'progress': encodeProgress(progress),
  },
  Finished(:final outcome) => {
    'kind': 'finished',
    'outcome': encodeOutcome(outcome, encodeOutput),
  },
};

ProgramMessage<O> decodeProgramMessage<O>(
  Object? json,
  O Function(Object? json, String field) decodeOutput, [
  String field = 'programMessage',
]) {
  final map = _object(json, field);
  // wire-ok: this is the wire; decodeX pairs with encodeX above
  return switch (map['kind']) {
    'reported' => Reported(decodeProgress(map['progress'], '$field.progress')),
    'finished' => Finished(
      decodeOutcome(map['outcome'], decodeOutput, '$field.outcome'),
    ),
    final other => throw FormatException(
      '$field.kind: not "reported" or "finished" ($other)',
    ),
  };
}

// Origin

Object? encodeOrigin(Origin origin) => origin.value.toString();

Origin decodeOrigin(Object? json, [String field = 'origin']) {
  final raw = _string(json, field);
  return Origin.parse(raw) ??
      (throw FormatException('$field: not an origin ($raw)'));
}

// Method

Object? encodeMethod(Method method) => method.name;

Method decodeMethod(Object? json, [String field = 'method']) {
  final raw = _string(json, field);
  return Method.values.where((m) => m.name == raw).firstOrNull ??
      (throw FormatException('$field: not a method ($raw)'));
}

// WebPath

Object? encodeWebPath(WebPath path) => path.value;

WebPath decodeWebPath(Object? json, [String field = 'path']) {
  final raw = _string(json, field);
  if (raw.isEmpty) return WebPath.root;
  return WebPath.parse(raw) ??
      (throw FormatException('$field: not a web path ($raw)'));
}

// SignIn

Object? encodeSignIn(SignIn signIn) => signIn.name;

SignIn decodeSignIn(Object? json, [String field = 'signIn']) {
  final raw = _string(json, field);
  return SignIn.parse(raw) ??
      (throw FormatException('$field: not a sign-in ($raw)'));
}

// ModelSignInName

Object? encodeModelSignInName(ModelSignInName signIn) => signIn.name;

ModelSignInName decodeModelSignInName(
  Object? json, [
  String field = 'modelSignIn',
]) {
  final raw = _string(json, field);
  return ModelSignInName.parse(raw) ??
      (throw FormatException('$field: not a model sign-in ($raw)'));
}

// ModelName

Object? encodeModelName(ModelName model) => model.value;

ModelName decodeModelName(Object? json, [String field = 'model']) {
  final raw = _string(json, field);
  return ModelName.parse(raw) ??
      (throw FormatException('$field: not a model name ($raw)'));
}

// ModelAndSignIn

Object? encodeModelAndSignIn(ModelAndSignIn pair) => {
  'signIn': encodeModelSignInName(pair.signIn),
  'model': encodeModelName(pair.model),
};

ModelAndSignIn decodeModelAndSignIn(
  Object? json, [
  String field = 'modelAndSignIn',
]) {
  final map = _object(json, field);
  return ModelAndSignIn(
    signIn: decodeModelSignInName(map['signIn'], '$field.signIn'),
    model: decodeModelName(map['model'], '$field.model'),
  );
}

// BotPool

Object? encodeBotPool(BotPool pool) => pool.name;

BotPool decodeBotPool(Object? json, [String field = 'botPool']) {
  final raw = _string(json, field);
  return BotPool.parse(raw) ??
      (throw FormatException('$field: not a bot pool ($raw)'));
}

// ModelUsage

Object? encodeModelUsage(ModelUsage usage) => {
  'input': usage.input,
  'cacheRead': usage.cacheRead,
  'output': usage.output,
  'cacheCreation': usage.cacheCreation,
  'contextWindow': usage.contextWindow,
};

ModelUsage decodeModelUsage(Object? json, [String field = 'modelUsage']) {
  final map = _object(json, field);
  return ModelUsage(
    input: _int(map['input'], '$field.input'),
    cacheRead: _int(map['cacheRead'], '$field.cacheRead'),
    output: _int(map['output'], '$field.output'),
    cacheCreation: switch (map['cacheCreation']) {
      null => null,
      final int n => n,
      _ => throw FormatException('$field.cacheCreation: not an int'),
    },
    contextWindow: switch (map['contextWindow']) {
      null => null,
      final int n => n,
      _ => throw FormatException('$field.contextWindow: not an int'),
    },
  );
}

// ModelReply

Object? encodeModelReply(ModelReply reply) {
  // A finished reply with no usage: the bare string every reply encoded
  // as before 0.9.0, unchanged.
  if (reply is FinishedReply && reply.usage == null) return reply.text;
  return {
    'text': reply.text,
    if (reply.usage != null) 'usage': encodeModelUsage(reply.usage!),
    if (reply is CutOffReply) 'incomplete': true,
  };
}

ModelReply decodeModelReply(Object? json, [String field = 'modelReply']) {
  // A reply recorded before 0.9.0, or any driver that has no usage to
  // add: just the text, exactly as decodeModelReply always read it — and
  // always finished, since a driver with no usage has no way to say
  // "incomplete" either.
  if (json case final String text) return FinishedReply(text: text);
  final map = _object(json, field);
  final text = _string(map['text'], '$field.text');
  final usage = map['usage'] == null
      ? null
      : decodeModelUsage(map['usage'], '$field.usage');
  final cutOff = map.containsKey('incomplete')
      ? _bool(map['incomplete'], '$field.incomplete')
      : false;
  return cutOff
      ? CutOffReply(text: text, usage: usage)
      : FinishedReply(text: text, usage: usage);
}

// ModelCall: the {signIn, model, systemPrompt, request} envelope sent over
// the socket to an AsksTheModel service, so a caller and the service can't
// disagree on field names or order.

Object? encodeModelCall(
  ModelSignInName signIn,
  ModelName model,
  String systemPrompt,
  String request,
) => {
  'signIn': encodeModelSignInName(signIn),
  'model': encodeModelName(model),
  'systemPrompt': systemPrompt,
  'request': request,
};

(ModelSignInName, ModelName, String, String) decodeModelCall(
  Object? json, [
  String field = 'modelCall',
]) {
  final map = _object(json, field);
  return (
    decodeModelSignInName(map['signIn'], '$field.signIn'),
    decodeModelName(map['model'], '$field.model'),
    _string(map['systemPrompt'], '$field.systemPrompt'),
    _string(map['request'], '$field.request'),
  );
}

// Headers

Object? encodeHeaders(Map<String, String> headers) => headers;

Map<String, String> decodeHeaders(Object? json, [String field = 'headers']) {
  final map = _object(json, field);
  final headers = <String, String>{};
  for (final entry in map.entries) {
    if (isCredentialHeader(entry.key)) {
      throw FormatException(
        "$field.${entry.key}: carries a credential, which is the sign-in's",
      );
    }
    headers[entry.key] = _string(entry.value, '$field.${entry.key}');
  }
  return Map.unmodifiable(headers);
}

// Request

Object? encodeRequest(Request request) => {
  'origin': encodeOrigin(request.origin),
  'method': encodeMethod(request.method),
  'path': encodeWebPath(request.path),
  'signIn': request.signIn == null ? null : encodeSignIn(request.signIn!),
  'headers': encodeHeaders(request.headers),
  'body': request.body,
  if (request.keep != BodyToKeep.none) 'keep': encodeBodyToKeep(request.keep),
};

Request decodeRequest(Object? json, [String field = 'request']) {
  final map = _object(json, field);
  return Request(
    decodeOrigin(map['origin'], '$field.origin'),
    method: map.containsKey('method')
        ? decodeMethod(map['method'], '$field.method')
        : Method.get,
    path: map.containsKey('path')
        ? decodeWebPath(map['path'], '$field.path')
        : WebPath.root,
    signIn: map['signIn'] == null
        ? null
        : decodeSignIn(map['signIn'], '$field.signIn'),
    headers: map.containsKey('headers')
        ? decodeHeaders(map['headers'], '$field.headers')
        : const {},
    body: switch (map['body']) {
      null => null,
      final String body => body,
      _ => throw FormatException('$field.body: not a string'),
    },
    keep: map.containsKey('keep')
        ? decodeBodyToKeep(map['keep'], '$field.keep')
        : BodyToKeep.none,
  );
}

// BodyToKeep

Object? encodeBodyToKeep(BodyToKeep keep) => keep.name;

BodyToKeep decodeBodyToKeep(Object? json, [String field = 'keep']) {
  final raw = _string(json, field);
  return BodyToKeep.values.where((k) => k.name == raw).firstOrNull ??
      (throw FormatException('$field: not a body to keep ($raw)'));
}

// ResponseBody

Object? encodeResponseBody(ResponseBody body) => switch (body) {
  NoBody() => {'kind': 'none'},
  TextBody(:final text) => {'kind': 'text', 'text': text},
  BytesBody(:final bytes) => {'kind': 'bytes', 'base64': base64Encode(bytes)},
};

ResponseBody decodeResponseBody(Object? json, [String field = 'body']) {
  final map = _object(json, field);
  // wire-ok: this is the wire; decodeX pairs with encodeX above
  return switch (map['kind']) {
    'none' => const NoBody(),
    'text' => TextBody(_string(map['text'], '$field.text')),
    'bytes' => BytesBody(_base64(map['base64'], '$field.base64')),
    final other => throw FormatException(
      '$field.kind: not "none", "text" or "bytes" ($other)',
    ),
  };
}

// RedirectedTo

Object? encodeRedirectedTo(RedirectedTo to) => to.value.toString();

RedirectedTo decodeRedirectedTo(Object? json, [String field = 'redirectedTo']) {
  final raw = _string(json, field);
  return RedirectedTo.parse(raw) ??
      (throw FormatException(
        '$field: not an http(s) address without query or credentials',
      ));
}

// WebResponse

Object? encodeWebResponse(WebResponse response) => {
  'status': response.status,
  'created': response.created,
  'refusedBecause': response.refusedBecause,
  if (response.body is! NoBody) 'body': encodeResponseBody(response.body),
  if (response.redirects.isNotEmpty)
    'redirects': [for (final to in response.redirects) encodeRedirectedTo(to)],
};

WebResponse decodeWebResponse(Object? json, [String field = 'webResponse']) {
  final map = _object(json, field);
  return WebResponse(
    status: _int(map['status'], '$field.status'),
    created: switch (map['created']) {
      null => null,
      final String created => created,
      _ => throw FormatException('$field.created: not a string'),
    },
    refusedBecause: switch (map['refusedBecause']) {
      null => null,
      final String why => why,
      _ => throw FormatException('$field.refusedBecause: not a string'),
    },
    body: map.containsKey('body')
        ? decodeResponseBody(map['body'], '$field.body')
        : const NoBody(),
    redirects: switch (map['redirects']) {
      null => const [],
      final List<Object?> list => [
        for (final (i, to) in list.indexed)
          decodeRedirectedTo(to, '$field.redirects[$i]'),
      ],
      _ => throw FormatException('$field.redirects: not a list'),
    },
  );
}

// Outcome<O>

Object? encodeOutcome<O>(
  Outcome<O> outcome,
  Object? Function(O output) encodeOutput,
) => switch (outcome) {
  Ran(:final output) => {'kind': 'ran', 'output': encodeOutput(output)},
  Refused(:final why) => {'kind': 'refused', 'why': why},
};

Outcome<O> decodeOutcome<O>(
  Object? json,
  O Function(Object? json, String field) decodeOutput, [
  String field = 'outcome',
]) {
  final map = _object(json, field);
  // wire-ok: this is the wire; decodeX pairs with encodeX above
  return switch (map['kind']) {
    'ran' => Ran(decodeOutput(map['output'], '$field.output')),
    'refused' => Refused(_string(map['why'], '$field.why')),
    final other => throw FormatException(
      '$field.kind: not "ran" or "refused" ($other)',
    ),
  };
}
