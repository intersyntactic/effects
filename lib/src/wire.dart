import 'file.dart';
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
  return switch (map['kind']) {
    'text' => ReadText(_string(map['text'], '$field.text')),
    'missing' => const ReadMissing(),
    final other => throw FormatException(
      '$field.kind: not "text" or "missing" ($other)',
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

// Start: what StartsPrograms.start is given

Object? encodeStart(ProgramName program, Args args) => {
  'program': encodeProgramName(program),
  'args': encodeArgs(args),
};

(ProgramName, Args) decodeStart(Object? json, [String field = 'start']) {
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
};

Progress decodeProgress(Object? json, [String field = 'progress']) {
  final map = _object(json, field);
  return switch (map['kind']) {
    'printed' => Printed(switch (map['channel']) {
      'stdout' => Channel.stdout,
      'stderr' => Channel.stderr,
      final other => throw FormatException(
        '$field.channel: not "stdout" or "stderr" ($other)',
      ),
    }, _string(map['text'], '$field.text')),
    final other => throw FormatException('$field.kind: not "printed" ($other)'),
  };
}

// ProgramMessage

Object? encodeProgramMessage(ProgramMessage message) => switch (message) {
  Reported(:final progress) => {
    'kind': 'reported',
    'progress': encodeProgress(progress),
  },
  Finished(:final outcome) => {
    'kind': 'finished',
    'outcome': encodeOutcome(outcome, encodeExecResult),
  },
};

ProgramMessage decodeProgramMessage(
  Object? json, [
  String field = 'programMessage',
]) {
  final map = _object(json, field);
  return switch (map['kind']) {
    'reported' => Reported(decodeProgress(map['progress'], '$field.progress')),
    'finished' => Finished(
      decodeOutcome(map['outcome'], decodeExecResult, '$field.outcome'),
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
  );
}

// WebRequestOutcome

Object? encodeWebRequestOutcome(WebRequestOutcome outcome) => {
  'status': outcome.status,
  'created': outcome.created,
  'refusedBecause': outcome.refusedBecause,
};

WebRequestOutcome decodeWebRequestOutcome(
  Object? json, [
  String field = 'webRequestOutcome',
]) {
  final map = _object(json, field);
  return WebRequestOutcome(
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
  return switch (map['kind']) {
    'ran' => Ran(decodeOutput(map['output'], '$field.output')),
    'refused' => Refused(_string(map['why'], '$field.why')),
    final other => throw FormatException(
      '$field.kind: not "ran" or "refused" ($other)',
    ),
  };
}
