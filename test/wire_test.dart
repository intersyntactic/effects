import 'dart:convert';
import 'dart:typed_data';

import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

void main() {
  group('RelativePath', () {
    test('round-trips', () {
      final path = RelativePath('a/b');
      expect(decodeRelativePath(encodeRelativePath(path)), path);
    });

    test('refuses a non-string', () {
      expect(() => decodeRelativePath(1), throwsFormatException);
    });
  });

  group('FileText', () {
    test('round-trips', () {
      final file = FileText(RelativePath('a.txt'), 'hello');
      final decoded = decodeFileText(encodeFileText(file));
      expect(decoded.path, file.path);
      expect(decoded.text, file.text);
    });

    test('refuses a missing field, naming it', () {
      expect(
        () => decodeFileText({'path': 'a.txt'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('file.text'),
          ),
        ),
      );
    });
  });

  group('ProgramName', () {
    test('round-trips', () {
      final name = ProgramName.parse('git')!;
      expect(decodeProgramName(encodeProgramName(name)), name);
    });

    test('refuses whitespace', () {
      expect(() => decodeProgramName('git status'), throwsFormatException);
    });

    test('refuses a path, a dot name or a NUL: a program is named', () {
      for (final raw in [
        '/bin/sh',
        '../../x',
        './gradlew',
        'bin/git',
        '.',
        '..',
        'git\u0000',
        '',
      ]) {
        expect(ProgramName.parse(raw), isNull, reason: raw);
      }
    });

    test('a set encodes sorted and round-trips', () {
      final names = {
        for (final raw in ['git', 'dart', 'python3.12'])
          ProgramName.parse(raw)!,
      };
      expect(encodeProgramNames(names), ['dart', 'git', 'python3.12']);
      expect(
        decodeProgramNames(jsonDecode(jsonEncode(encodeProgramNames(names)))),
        names,
      );
      expect(encodeProgramNames({}), isEmpty);
      expect(decodeProgramNames(<Object?>[]), isEmpty);
    });

    test('a set refuses a non-list, a bad name or a duplicate, naming it', () {
      Matcher naming(String text) => throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains(text),
        ),
      );
      expect(() => decodeProgramNames('git'), naming('programs: not a list'));
      expect(() => decodeProgramNames(['git', 3]), naming('programs[1]'));
      expect(
        () => decodeProgramNames(['git', '/bin/sh']),
        naming('programs[1]'),
      );
      expect(
        () => decodeProgramNames(['git', 'dart', 'git']),
        naming('programs[2]: git is listed twice'),
      );
    });

    test('accepts names with dots and dashes inside', () {
      for (final raw in ['python3.12', 'git-lfs', '.hidden', 'a..b']) {
        expect(ProgramName.parse(raw)?.value, raw);
      }
    });
  });

  group('Args', () {
    test('round-trips, with defaults', () {
      final args = Args(['status']);
      final decoded = decodeArgs(encodeArgs(args));
      expect(decoded.args, args.args);
      expect(decoded.stdin, isNull);
      expect(decoded.inFolder, RelativePath.root);
    });

    test('round-trips with stdin and inFolder set', () {
      final args = Args(
        ['a', 'b'],
        stdin: 'input',
        inFolder: RelativePath('sub'),
      );
      final decoded = decodeArgs(encodeArgs(args));
      expect(decoded.args, args.args);
      expect(decoded.stdin, args.stdin);
      expect(decoded.inFolder, args.inFolder);
    });
  });

  group('ReadResult', () {
    test('round-trips ReadText', () {
      expect(
        (decodeReadResult(
          encodeReadResult(const ReadText('hi')),
        ) as ReadText).text,
        'hi',
      );
    });

    test('round-trips ReadMissing', () {
      expect(
        decodeReadResult(encodeReadResult(const ReadMissing())),
        isA<ReadMissing>(),
      );
    });

    test('refuses an unknown kind', () {
      expect(() => decodeReadResult({'kind': 'huh'}), throwsFormatException);
    });
  });

  group('BytesReadResult', () {
    test('round-trips ReadBytes, including bytes that are not UTF-8', () {
      final bytes = Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 0xff, 0x00]);
      expect(
        (decodeBytesReadResult(
          encodeBytesReadResult(ReadBytes(bytes)),
        ) as ReadBytes).bytes,
        bytes,
      );
    });

    test('round-trips ReadMissing', () {
      expect(
        decodeBytesReadResult(encodeBytesReadResult(const ReadMissing())),
        isA<ReadMissing>(),
      );
    });

    test('refuses bytes that are not base64', () {
      expect(
        () => decodeBytesReadResult({'kind': 'bytes', 'base64': '!!'}),
        throwsFormatException,
      );
    });

    test('refuses a text result', () {
      expect(
        () => decodeBytesReadResult({'kind': 'text', 'text': 'hi'}),
        throwsFormatException,
      );
    });
  });

  group('Wrote', () {
    test('round-trips', () {
      expect(
        decodeWrote(encodeWrote(const Wrote(replaced: true))).replaced,
        true,
      );
    });
  });

  group('ExecResult', () {
    test('round-trips Exited', () {
      final result = const Exited(0, stdout: 'out', stderr: '');
      final decoded = decodeExecResult(encodeExecResult(result)) as Exited;
      expect(decoded.exitCode, 0);
      expect(decoded.stdout, 'out');
    });

    test('round-trips Killed', () {
      final result = const Killed('timed out', stdout: '', stderr: 'err');
      final decoded = decodeExecResult(encodeExecResult(result)) as Killed;
      expect(decoded.why, 'timed out');
      expect(decoded.stderr, 'err');
    });
  });

  group('ProgramToRun', () {
    test('round-trips', () {
      final (program, args) = decodeProgramToRun(
        encodeProgramToRun(ProgramName.parse('git')!, Args(['status'])),
      );
      expect(program, ProgramName.parse('git'));
      expect(args.args, ['status']);
    });

    test('refuses a bad program, naming it', () {
      expect(
        () => decodeProgramToRun({
          'program': 'git status',
          'args': {'args': <String>[]},
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('programToRun.program'),
          ),
        ),
      );
    });
  });

  group('ProgramRequest', () {
    final run = RunProgramRequest(
      ProgramName.parse('git')!,
      const Args(['status'], stdin: 'x'),
    );

    test('each kind is the exact JSON program_driver 0.2.2 reads', () {
      // program_driver's RunProgram.toJson, byte for byte.
      expect(
        jsonEncode(encodeProgramRequest(run)),
        jsonEncode({
          'kind': 'run',
          'programToRun': encodeProgramToRun(run.program, run.args),
        }),
      );
      expect(
        jsonEncode(encodeProgramRequest(const ListInstalledProgramsRequest())),
        '{"kind":"list"}',
      );
    });

    test('round-trips each kind', () {
      final decoded =
          decodeProgramRequest(encodeProgramRequest(run)) as RunProgramRequest;
      expect(decoded.program, run.program);
      expect(decoded.args.args, ['status']);
      expect(decoded.args.stdin, 'x');

      expect(
        decodeProgramRequest({'kind': 'list'}),
        isA<ListInstalledProgramsRequest>(),
      );
    });

    test('refuses an unknown kind, naming it', () {
      expect(
        () => decodeProgramRequest({'kind': 'kill'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('kill'),
          ),
        ),
      );
    });
  });

  group('FileRequest', () {
    test('each kind is the JSON file_driver already sends', () {
      expect(encodeFileRequest(ReadFileRequest(RelativePath('a.txt'))), {
        'kind': 'read',
        'path': 'a.txt',
      });
      expect(encodeFileRequest(ReadFileBytesRequest(RelativePath('b.docx'))), {
        'kind': 'readBytes',
        'path': 'b.docx',
      });
      expect(
        encodeFileRequest(WriteFileRequest(FileText(RelativePath('c'), 'hi'))),
        {
          'kind': 'write',
          'file': {'path': 'c', 'text': 'hi'},
        },
      );
    });

    test('round-trips each kind', () {
      final read = decodeFileRequest({'kind': 'read', 'path': 'a.txt'});
      expect((read as ReadFileRequest).path, RelativePath('a.txt'));

      final bytes = decodeFileRequest({'kind': 'readBytes', 'path': 'b'});
      expect((bytes as ReadFileBytesRequest).path, RelativePath('b'));

      final write = decodeFileRequest(
        encodeFileRequest(WriteFileRequest(FileText(RelativePath('c'), 'hi'))),
      );
      expect((write as WriteFileRequest).file.path, RelativePath('c'));
      expect(write.file.text, 'hi');
    });

    test('refuses an unknown kind, naming it', () {
      expect(
        () => decodeFileRequest({'kind': 'delete', 'path': 'a'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('fileRequest.kind'),
          ),
        ),
      );
    });

    test('refuses a write with no text, naming the field', () {
      expect(
        () => decodeFileRequest({
          'kind': 'write',
          'file': {'path': 'c'},
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('fileRequest.file.text'),
          ),
        ),
      );
    });
  });

  group('Progress', () {
    test('round-trips ReplyArriving', () {
      final decoded = decodeProgress(
        encodeProgress(const ReplyArriving('hi')),
      ) as ReplyArriving;
      expect(decoded.text, 'hi');
    });

    test('refuses an unknown kind, naming it', () {
      expect(
        () => decodeProgress({'kind': 'spoken', 'text': ''}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('progress.kind'),
          ),
        ),
      );
    });
  });

  group('ProgramMessage<ExecResult>', () {
    test('a printed line is this JSON', () {
      expect(
        encodeProgramMessage(
          const Reported<ExecResult>(Printed(Channel.stderr, 'warning\n')),
          encodeExecResult,
        ),
        {
          'kind': 'reported',
          'progress': {
            'kind': 'printed',
            'channel': 'stderr',
            'text': 'warning\n',
          },
        },
      );
    });

    test('round-trips Reported', () {
      final decoded = decodeProgramMessage(
        encodeProgramMessage(
          const Reported<ExecResult>(Printed(Channel.stdout, 'hi')),
          encodeExecResult,
        ),
        decodeExecResult,
      ) as Reported<ExecResult>;
      final printed = decoded.progress as Printed;
      expect(printed.channel, Channel.stdout);
      expect(printed.text, 'hi');
    });

    test('round-trips Finished', () {
      final decoded = decodeProgramMessage(
        encodeProgramMessage(
          Finished<ExecResult>(Ran(const Exited(1, stdout: '', stderr: 'no'))),
          encodeExecResult,
        ),
        decodeExecResult,
      ) as Finished<ExecResult>;
      final exited = (decoded.outcome as Ran<ExecResult>).output as Exited;
      expect(exited.exitCode, 1);
      expect(exited.stderr, 'no');
    });

    test('refuses an unknown channel, naming it', () {
      expect(
        () => decodeProgramMessage({
          'kind': 'reported',
          'progress': {'kind': 'printed', 'channel': 'stdin', 'text': ''},
        }, decodeExecResult),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('programMessage.progress.channel'),
          ),
        ),
      );
    });

    // Bytes captured from enspyr-syd's program-driver socket
    // (infra-5e, 2026-11-17): genericizing Reported/Finished must not move
    // a single byte on the wire a deployed program_driver still speaks.
    test('encodes exactly the bytes the deployed driver speaks', () {
      expect(
        jsonEncode(
          encodeProgramMessage(
            const Reported<ExecResult>(Printed(Channel.stdout, 'out\n')),
            encodeExecResult,
          ),
        ),
        '{"kind":"reported","progress":'
        '{"kind":"printed","channel":"stdout","text":"out\\n"}}',
      );
      expect(
        jsonEncode(
          encodeProgramMessage(
            Finished<ExecResult>(
              Ran(const Exited(0, stdout: 'out\n', stderr: 'err\n')),
            ),
            encodeExecResult,
          ),
        ),
        '{"kind":"finished","outcome":{"kind":"ran","output":'
        '{"kind":"exited","exitCode":0,"stdout":"out\\n","stderr":"err\\n"}}}',
      );
      expect(
        jsonEncode(
          encodeProgramMessage(
            Finished<ExecResult>(
              Ran(const Killed('timed out after 5s', stdout: '', stderr: '')),
            ),
            encodeExecResult,
          ),
        ),
        '{"kind":"finished","outcome":{"kind":"ran","output":'
        '{"kind":"killed","why":"timed out after 5s","stdout":"","stderr":""}}}',
      );
    });
  });

  group('ProgramMessage<ModelReply>', () {
    test('round-trips Finished with a model reply', () {
      final decoded = decodeProgramMessage(
        encodeProgramMessage(
          Finished<ModelReply>(Ran(const FinishedReply(text: 'hi'))),
          encodeModelReply,
        ),
        decodeModelReply,
      ) as Finished<ModelReply>;
      final reply = (decoded.outcome as Ran<ModelReply>).output;
      expect(reply.text, 'hi');
    });

    test('"kind" comes before "outcome": infra-5e\'s probe matches on it', () {
      expect(
        jsonEncode(
          encodeProgramMessage(
            Finished<ModelReply>(const Refused('no sign-in')),
            encodeModelReply,
          ),
        ),
        startsWith('{"kind":"finished","outcome":{"kind":"refused"'),
      );
    });
  });

  group('ModelCall', () {
    test('is this JSON, key order and all', () {
      expect(
        jsonEncode(
          encodeModelCall(
            ModelSignInName.parse('anthropic-api')!,
            ModelName.parse('claude-opus-5-5')!,
            'be terse',
            'hello',
          ),
        ),
        '{"signIn":"anthropic-api","model":"claude-opus-5-5",'
        '"systemPrompt":"be terse","request":"hello"}',
      );
    });

    test('round-trips, byte-exact, even with BOM/NUL/CRLF/non-ASCII', () {
      const systemPrompt = '﻿  leading and trailing  ';
      const request = 'line1\r\nline2\x00café';
      final (signIn, model, decodedPrompt, decodedRequest) = decodeModelCall(
        encodeModelCall(
          ModelSignInName.parse('anthropic-api')!,
          ModelName.parse('claude-opus-5-5')!,
          systemPrompt,
          request,
        ),
      );
      expect(signIn, ModelSignInName.parse('anthropic-api'));
      expect(model, ModelName.parse('claude-opus-5-5'));
      expect(decodedPrompt, systemPrompt);
      expect(decodedRequest, request);
    });

    test('refuses with a FormatException, naming the missing field', () {
      expect(
        () => decodeModelCall({
          'signIn': 'anthropic-api',
          'model': 'claude-opus-5-5',
          'systemPrompt': 'be terse',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('refuses a non-object with a FormatException', () {
      expect(() => decodeModelCall('not an object'), throwsFormatException);
    });

    test('ignores extra keys', () {
      final (signIn, model, systemPrompt, request) = decodeModelCall({
        'signIn': 'anthropic-api',
        'model': 'claude-opus-5-5',
        'systemPrompt': 'be terse',
        'request': 'hello',
        'caller': 'should be ignored',
      });
      expect(signIn, ModelSignInName.parse('anthropic-api'));
      expect(model, ModelName.parse('claude-opus-5-5'));
      expect(systemPrompt, 'be terse');
      expect(request, 'hello');
    });
  });

  group('Method', () {
    for (final method in Method.values) {
      test('round-trips $method', () {
        expect(decodeMethod(encodeMethod(method)), method);
      });
    }

    test('refuses an unknown method', () {
      expect(() => decodeMethod('fetch'), throwsFormatException);
    });
  });

  group('ModelSignInName', () {
    test('round-trips', () {
      final signIn = ModelSignInName.parse('anthropic-api')!;
      expect(decodeModelSignInName(encodeModelSignInName(signIn)), signIn);
    });

    test('refuses an invalid name', () {
      expect(() => decodeModelSignInName('Not Valid'), throwsFormatException);
    });
  });

  group('ModelName', () {
    test('round-trips', () {
      final model = ModelName.parse('claude-opus-5-5')!;
      expect(decodeModelName(encodeModelName(model)), model);
    });

    test('refuses whitespace', () {
      expect(() => decodeModelName('claude opus'), throwsFormatException);
    });
  });

  group('BotPool', () {
    test('round-trips', () {
      final pool = BotPool.parse('teams')!;
      expect(decodeBotPool(encodeBotPool(pool)), pool);
    });

    test('refuses an invalid name', () {
      expect(() => decodeBotPool('Teams Pool'), throwsFormatException);
    });
  });

  group('ModelAndSignIn', () {
    final pair = ModelAndSignIn(
      signIn: ModelSignInName.parse('nick-claude-team')!,
      model: ModelName.parse('claude-opus-5-5')!,
    );

    test('round-trips', () {
      expect(decodeModelAndSignIn(encodeModelAndSignIn(pair)), pair);
    });

    test('is written as signIn and model', () {
      expect(encodeModelAndSignIn(pair), {
        'signIn': 'nick-claude-team',
        'model': 'claude-opus-5-5',
      });
    });

    test('refuses an invalid sign-in, naming the field', () {
      expect(
        () => decodeModelAndSignIn({
          'signIn': 'Not Valid',
          'model': 'claude-opus-5-5',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('modelAndSignIn.signIn'),
          ),
        ),
      );
    });
  });

  group('ModelUsage', () {
    test('context is input + cacheRead + cacheCreation, never output', () {
      const usage = ModelUsage(
        input: 100,
        cacheRead: 20,
        output: 500,
        cacheCreation: 7,
      );
      expect(usage.context, 127);
    });

    test('context treats a null cacheCreation as none spent', () {
      const usage = ModelUsage(input: 100, cacheRead: 20, output: 500);
      expect(usage.context, 120);
    });

    test('round-trips, with cacheCreation and contextWindow null', () {
      const usage = ModelUsage(input: 10, cacheRead: 2, output: 30);
      final decoded = decodeModelUsage(encodeModelUsage(usage));
      expect(decoded, usage);
      expect(decoded.cacheCreation, isNull);
      expect(decoded.contextWindow, isNull);
    });

    test('round-trips, every field present', () {
      const usage = ModelUsage(
        input: 10,
        cacheRead: 2,
        output: 30,
        cacheCreation: 4,
        contextWindow: 1000000,
      );
      expect(decodeModelUsage(encodeModelUsage(usage)), usage);
    });
  });

  group('ModelReply', () {
    test('a finished reply with no usage is still the bare string', () {
      expect(encodeModelReply(const FinishedReply(text: 'hi')), 'hi');
    });

    test('round-trips a bare string as a FinishedReply', () {
      final reply = FinishedReply(text: '{"text": "hi"}');
      final decoded = decodeModelReply(encodeModelReply(reply));
      expect(decoded, isA<FinishedReply>());
      expect(decoded.text, reply.text);
    });

    test('decodes a reply recorded before usage or incomplete existed', () {
      final decoded = decodeModelReply('hi');
      expect(decoded, isA<FinishedReply>());
      expect(decoded.text, 'hi');
      expect(decoded.usage, isNull);
    });

    test('refuses a non-string, non-object', () {
      expect(() => decodeModelReply(1), throwsFormatException);
    });

    test('round-trips a FinishedReply with usage', () {
      const usage = ModelUsage(input: 10, cacheRead: 0, output: 5);
      final reply = const FinishedReply(text: 'hi', usage: usage);
      final decoded = decodeModelReply(encodeModelReply(reply));
      expect(decoded, isA<FinishedReply>());
      expect(decoded.text, 'hi');
      expect(decoded.usage, usage);
    });

    test('round-trips a CutOffReply', () {
      final reply = const CutOffReply(text: 'cut off mid');
      final decoded = decodeModelReply(encodeModelReply(reply));
      expect(decoded, isA<CutOffReply>());
      expect(decoded.text, 'cut off mid');
    });

    test('round-trips a CutOffReply with usage', () {
      const usage = ModelUsage(input: 10, cacheRead: 0, output: 5);
      final reply = const CutOffReply(text: 'cut off mid', usage: usage);
      final decoded = decodeModelReply(encodeModelReply(reply));
      expect(decoded, isA<CutOffReply>());
      expect(decoded.text, 'cut off mid');
      expect(decoded.usage, usage);
    });

    test('encodes a FinishedReply with usage, keyed, not as a bare string', () {
      const usage = ModelUsage(input: 10, cacheRead: 0, output: 5);
      expect(encodeModelReply(const FinishedReply(text: 'hi', usage: usage)), {
        'text': 'hi',
        'usage': {
          'input': 10,
          'cacheRead': 0,
          'output': 5,
          'cacheCreation': null,
          'contextWindow': null,
        },
      });
    });

    test('encodes a CutOffReply with incomplete, even with no usage', () {
      expect(encodeModelReply(const CutOffReply(text: 'cut off mid')), {
        'text': 'cut off mid',
        'incomplete': true,
      });
    });

    test('a switch over ModelReply must handle both cases', () {
      String describe(ModelReply reply) => switch (reply) {
        FinishedReply() => 'finished',
        CutOffReply() => 'cut off',
      };
      expect(describe(const FinishedReply(text: 'hi')), 'finished');
      expect(describe(const CutOffReply(text: 'hi')), 'cut off');
    });
  });

  group('headers', () {
    test('round-trips', () {
      final headers = {'content-type': 'application/json'};
      expect(decodeHeaders(encodeHeaders(headers)), headers);
    });

    test('refuses a credential header', () {
      expect(
        () => decodeHeaders({'authorization': 'secret'}),
        throwsFormatException,
      );
    });
  });

  group('ProposedRequest and GrantedRequest', () {
    final origin = Origin.parse('https://api.example.com')!;

    test('round-trips with defaults', () {
      final request = ProposedRequest(origin);
      final decoded = decodeProposedRequest(encodeProposedRequest(request));
      expect(decoded.origin, origin);
      expect(decoded.method, Method.get);
      expect(decoded.path, WebPath.root);
      expect(decoded.signIn, isNull);
      expect(decoded.headers, isEmpty);
      expect(decoded.body, isNull);
    });

    test('round-trips every field set', () {
      final request = ProposedRequest(
        origin,
        method: Method.post,
        path: WebPath.parse('/v3/send')!,
        signIn: SignIn.parse('some-bot'),
        headers: const {'content-type': 'application/json'},
        body: '{}',
      );
      final decoded = decodeProposedRequest(encodeProposedRequest(request));
      expect(decoded.origin, request.origin);
      expect(decoded.method, request.method);
      expect(decoded.path, request.path);
      expect(decoded.signIn, request.signIn);
      expect(decoded.headers, request.headers);
      expect(decoded.body, request.body);
      expect(decoded.keep, BodyToKeep.none);
    });

    test('round-trips what to keep of the body', () {
      for (final keep in BodyToKeep.values) {
        final decoded = decodeProposedRequest(
          encodeProposedRequest(ProposedRequest(origin, keep: keep)),
        );
        expect(decoded.keep, keep);
      }
    });

    test('writes no keep when it keeps nothing, as before', () {
      expect(
        encodeProposedRequest(ProposedRequest(origin)),
        isNot(contains('keep')),
      );
    });

    test('a proposal that claims a grant is refused, naming the key', () {
      expect(
        () => decodeProposedRequest({
          'origin': 'https://api.example.com',
          'path': '/v1.0/drives/d/x',
          'grantedPathPrefix': '/v1.0/drives/d/',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('request.grantedPathPrefix: a proposal carries no grant'),
          ),
        ),
      );
    });

    test('a granted request round-trips with its prefix', () {
      final granted = GrantedRequest.under(
        ProposedRequest(
          origin,
          method: Method.post,
          path: WebPath.parse('/v1.0/drives/d/items/i/content')!,
          signIn: SignIn.parse('some-bot'),
          body: '{}',
          keep: BodyToKeep.bytes,
        ),
        PathPrefix.parse('/v1.0/drives/d/')!,
      );
      final json = jsonDecode(jsonEncode(encodeGrantedRequest(granted)));
      expect(json, containsPair('grantedPathPrefix', '/v1.0/drives/d/'));
      final decoded = decodeGrantedRequest(json);
      expect(decoded.grantedPathPrefix, granted.grantedPathPrefix);
      expect(decoded.proposed.path, granted.proposed.path);
      expect(decoded.proposed.method, Method.post);
      expect(decoded.proposed.signIn, granted.proposed.signIn);
      expect(decoded.proposed.body, '{}');
      expect(decoded.proposed.keep, BodyToKeep.bytes);
    });

    test('a granted request needs a prefix that covers its path', () {
      Matcher naming(String text) => throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains(text),
        ),
      );
      expect(
        () => decodeGrantedRequest({'origin': 'https://api.example.com'}),
        naming('request.grantedPathPrefix: missing'),
      );
      expect(
        () => decodeGrantedRequest({
          'origin': 'https://api.example.com',
          'path': '/v1.0/drives/other/x',
          'grantedPathPrefix': '/v1.0/drives/d/',
        }),
        naming('request.path: not under request.grantedPathPrefix'),
      );
      expect(
        () => decodeGrantedRequest({
          'origin': 'https://api.example.com',
          'grantedPathPrefix': '/no-slash',
        }),
        throwsFormatException,
      );
    });

    test('refuses a credential header, naming the field', () {
      expect(
        () => decodeProposedRequest({
          'origin': 'https://api.example.com',
          'headers': {'authorization': 'secret'},
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('request.headers'),
          ),
        ),
      );
    });
  });

  group('WebResponse', () {
    test('round-trips a success', () {
      final response = const WebResponse(status: 201, created: 'abc123');
      final decoded = decodeWebResponse(encodeWebResponse(response));
      expect(decoded.status, 201);
      expect(decoded.created, 'abc123');
      expect(decoded.refusedBecause, isNull);
    });

    test('round-trips a failure', () {
      final response = const WebResponse(
        status: 400,
        refusedBecause: 'bad request',
      );
      final decoded = decodeWebResponse(encodeWebResponse(response));
      expect(decoded.status, 400);
      expect(decoded.created, isNull);
      expect(decoded.refusedBecause, 'bad request');
    });

    test('writes no body or redirect when it has none, as before', () {
      expect(encodeWebResponse(const WebResponse(status: 200)), {
        'status': 200,
        'created': null,
        'refusedBecause': null,
      });
      expect(decodeWebResponse({'status': 200}).body, isA<NoBody>());
    });

    test('round-trips a text body', () {
      final decoded = decodeWebResponse(
        encodeWebResponse(
          const WebResponse(status: 200, body: TextBody('{"value":[]}')),
        ),
      );
      expect((decoded.body as TextBody).text, '{"value":[]}');
    });

    test('round-trips a bytes body that is not UTF-8', () {
      final bytes = Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 0xff, 0x00]);
      final decoded = decodeWebResponse(
        encodeWebResponse(WebResponse(status: 200, body: BytesBody(bytes))),
      );
      expect((decoded.body as BytesBody).bytes, bytes);
    });

    test('round-trips every followed redirect, in order', () {
      final hops = [
        RedirectedTo.of(Uri.parse('https://tenant.sharepoint.com/download'))!,
        RedirectedTo.of(Uri.parse('https://cdn.example.net/blob'))!,
      ];
      final decoded = decodeWebResponse(
        encodeWebResponse(WebResponse(status: 200, redirects: hops)),
      );
      expect(decoded.redirects, hops);
    });

    test('reads no redirects as none', () {
      expect(decodeWebResponse({'status': 200}).redirects, isEmpty);
    });

    test('refuses a recorded redirect that carries a query, naming it', () {
      expect(
        () => decodeWebResponse({
          'status': 200,
          'redirects': [
            'https://tenant.sharepoint.com/download',
            'https://cdn.example.net/blob?tempauth=secret',
          ],
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('webResponse.redirects[1]'),
          ),
        ),
      );
    });
  });

  group('RedirectedTo', () {
    test('drops the query, fragment and credentials', () {
      final to = RedirectedTo.of(
        Uri.parse('https://u:p@tenant.sharepoint.com/d.aspx?tempauth=x#f'),
      )!;
      expect(to.toString(), 'https://tenant.sharepoint.com/d.aspx');
    });

    test('is null for an address that is not http(s)', () {
      expect(RedirectedTo.of(Uri.parse('ftp://example.com/f')), isNull);
    });
  });

  group('Outcome', () {
    test('round-trips Ran', () {
      final outcome = Ran(const Wrote(replaced: false));
      final decoded = decodeOutcome<Wrote>(
        encodeOutcome(outcome, encodeWrote),
        decodeWrote,
      );
      expect((decoded as Ran<Wrote>).output.replaced, false);
    });

    test('round-trips Refused', () {
      final outcome = const Refused('denied');
      final decoded = decodeOutcome<Wrote>(
        encodeOutcome(outcome, encodeWrote),
        decodeWrote,
      );
      expect((decoded as Refused).why, 'denied');
    });
  });
}
