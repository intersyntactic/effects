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

  group('ProgramMessage', () {
    test('a printed line is this JSON', () {
      expect(
        encodeProgramMessage(
          const Reported(Printed(Channel.stderr, 'warning\n')),
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
        encodeProgramMessage(const Reported(Printed(Channel.stdout, 'hi'))),
      ) as Reported;
      final printed = decoded.progress as Printed;
      expect(printed.channel, Channel.stdout);
      expect(printed.text, 'hi');
    });

    test('round-trips Finished', () {
      final decoded = decodeProgramMessage(
        encodeProgramMessage(
          Finished(Ran(const Exited(1, stdout: '', stderr: 'no'))),
        ),
      ) as Finished;
      final exited = (decoded.outcome as Ran<ExecResult>).output as Exited;
      expect(exited.exitCode, 1);
      expect(exited.stderr, 'no');
    });

    test('refuses an unknown channel, naming it', () {
      expect(
        () => decodeProgramMessage({
          'kind': 'reported',
          'progress': {'kind': 'printed', 'channel': 'stdin', 'text': ''},
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('programMessage.progress.channel'),
          ),
        ),
      );
    });
  });

  group('Origin', () {
    test('round-trips', () {
      final origin = Origin.parse('https://api.example.com')!;
      expect(decodeOrigin(encodeOrigin(origin)), origin);
    });

    test('refuses a non-origin string', () {
      expect(() => decodeOrigin('not a url'), throwsFormatException);
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

  group('WebPath', () {
    test('round-trips an ordinary path', () {
      final path = WebPath.parse('/a/b')!;
      expect(decodeWebPath(encodeWebPath(path)), path);
    });

    test('round-trips root', () {
      expect(decodeWebPath(encodeWebPath(WebPath.root)), WebPath.root);
    });

    test('refuses an unsafe path', () {
      expect(() => decodeWebPath('/../x'), throwsFormatException);
      expect(() => decodeWebPath('/@evil.example'), throwsFormatException);
    });
  });

  group('SignIn', () {
    test('round-trips', () {
      final signIn = SignIn.parse('some-bot')!;
      expect(decodeSignIn(encodeSignIn(signIn)), signIn);
    });

    test('refuses an invalid name', () {
      expect(() => decodeSignIn('Not Valid'), throwsFormatException);
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

  group('Request', () {
    final origin = Origin.parse('https://api.example.com')!;

    test('round-trips with defaults', () {
      final request = Request(origin);
      final decoded = decodeRequest(encodeRequest(request));
      expect(decoded.origin, origin);
      expect(decoded.method, Method.get);
      expect(decoded.path, WebPath.root);
      expect(decoded.signIn, isNull);
      expect(decoded.headers, isEmpty);
      expect(decoded.body, isNull);
    });

    test('round-trips every field set', () {
      final request = Request(
        origin,
        method: Method.post,
        path: WebPath.parse('/v3/send')!,
        signIn: SignIn.parse('some-bot'),
        headers: const {'content-type': 'application/json'},
        body: '{}',
      );
      final decoded = decodeRequest(encodeRequest(request));
      expect(decoded.origin, request.origin);
      expect(decoded.method, request.method);
      expect(decoded.path, request.path);
      expect(decoded.signIn, request.signIn);
      expect(decoded.headers, request.headers);
      expect(decoded.body, request.body);
    });

    test('refuses a credential header, naming the field', () {
      expect(
        () => decodeRequest({
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

  group('WebRequestOutcome', () {
    test('round-trips a success', () {
      final outcome = const WebRequestOutcome(status: 201, created: 'abc123');
      final decoded = decodeWebRequestOutcome(encodeWebRequestOutcome(outcome));
      expect(decoded.status, 201);
      expect(decoded.created, 'abc123');
      expect(decoded.refusedBecause, isNull);
    });

    test('round-trips a failure', () {
      final outcome = const WebRequestOutcome(
        status: 400,
        refusedBecause: 'bad request',
      );
      final decoded = decodeWebRequestOutcome(encodeWebRequestOutcome(outcome));
      expect(decoded.status, 400);
      expect(decoded.created, isNull);
      expect(decoded.refusedBecause, 'bad request');
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
