import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

void main() {
  group('WebPath.parse', () {
    test('accepts an ordinary path', () {
      expect(
        WebPath.parse('/v3/conversations/abc/activities')?.value,
        '/v3/conversations/abc/activities',
      );
    });

    test('root is the empty path, not through parse', () {
      expect(WebPath.root.value, '');
    });

    test('refuses a path with no leading slash', () {
      expect(WebPath.parse('v3/conversations'), isNull);
      expect(WebPath.parse(''), isNull);
    });

    test('refuses a protocol-relative path', () {
      expect(WebPath.parse('//evil.example/x'), isNull);
    });

    test('refuses an authority-smuggling @', () {
      expect(WebPath.parse('/@evil.example/x'), isNull);
      expect(WebPath.parse('/x@evil.example'), isNull);
    });

    test('refuses a .. segment', () {
      expect(WebPath.parse('/a/../b'), isNull);
      expect(WebPath.parse('/..'), isNull);
    });

    test('equality is by value', () {
      expect(WebPath.parse('/a'), WebPath.parse('/a'));
      expect(WebPath.parse('/a'), isNot(WebPath.parse('/b')));
    });
  });

  group('validatedHeaders', () {
    test('passes through headers with no credential', () {
      final headers = validatedHeaders({'content-type': 'application/json'});
      expect(headers, {'content-type': 'application/json'});
    });

    test('is unmodifiable', () {
      final headers = validatedHeaders({});
      expect(() => headers['x'] = 'y', throwsUnsupportedError);
    });

    for (final name in [
      'authorization',
      'Authorization',
      'proxy-authorization',
      'cookie',
      'x-api-key',
    ]) {
      test('refuses a header carrying a credential: $name', () {
        expect(() => validatedHeaders({name: 'secret'}), throwsArgumentError);
      });
    }
  });

  group('Request', () {
    final origin = Origin.parse('https://api.example.com')!;

    test('defaults path to WebPath.root', () {
      expect(Request(origin).path, WebPath.root);
    });

    test('refuses a header carrying a credential', () {
      expect(
        () => Request(origin, headers: const {'authorization': 'x'}),
        throwsArgumentError,
      );
    });
  });
}
