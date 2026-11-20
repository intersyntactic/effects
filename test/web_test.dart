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

    test('refuses an escaped dot segment a parser would collapse', () {
      expect(WebPath.parse('/v1.0/drives/abc/%2e%2e/xyz/items'), isNull);
      expect(WebPath.parse('/v1.0/drives/abc/%2E%2E/xyz/items'), isNull);
      expect(WebPath.parse('/a/.%2E/b'), isNull);
      expect(WebPath.parse('/a/%2E./b'), isNull);
      expect(WebPath.parse('/a/./b'), isNull);
      expect(WebPath.parse('/a/.'), isNull);
      expect(WebPath.parse('/x%2F%2E%2E%2F'), isNull);
    });

    test('refuses an escaped percent, which a double decode would open', () {
      expect(WebPath.parse('/abc/%252e%252e/xyz'), isNull);
      expect(WebPath.parse('/a%25b'), isNull);
    });

    test('refuses an escape a parser would rewrite', () {
      expect(WebPath.parse('/a%2fb'), isNull);
      expect(WebPath.parse('/a b'), isNull);
      expect(WebPath.parse('/ä'), isNull);
    });

    test('accepts uppercase escapes with no dot', () {
      expect(WebPath.parse('/a%2Fb')?.value, '/a%2Fb');
      expect(
        WebPath.parse(
          '/amer/v3/conversations/${Uri.encodeComponent('19:abc@thread.tacv2')}'
          '/activities',
        ),
        isNotNull,
      );
    });

    test('accepts a query a parser leaves as it is', () {
      const listing =
          r'/v1.0/drives/d/root:/f:/children'
          r'?$select=name,size,lastModifiedDateTime,folder';
      expect(WebPath.parse(listing)?.value, listing);
    });

    test('refuses a query a parser would rewrite, and a fragment', () {
      expect(WebPath.parse(r'/a?$filter=name eq 1'), isNull);
      expect(WebPath.parse('/a?x=%2e'), isNull);
      expect(WebPath.parse('/a?x=1#f'), isNull);
      expect(WebPath.parse('/a#f'), isNull);
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
