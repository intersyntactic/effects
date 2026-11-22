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

    test('refuses a %25 a second decode would turn into structure', () {
      for (final escape in ['2e', '2E', '2f', '2F', '5c', '5C', '25']) {
        expect(WebPath.parse('/a/%25$escape/b'), isNull, reason: escape);
      }
      expect(WebPath.parse('/abc/%252e%252e/xyz'), isNull);
      expect(WebPath.parse('/abc/%252E%252e/xyz'), isNull);
    });

    test('accepts any other %25, an ordinary percent', () {
      final name = Uri.encodeComponent('50% budget.docx');
      expect(name, '50%25%20budget.docx');
      expect(WebPath.parse('/f:/$name:/content'), isNotNull);
      expect(WebPath.parse('/a%25b'), isNotNull);
      expect(WebPath.parse('/a%252'), isNotNull);
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

    test('carries the granted path prefix, which must cover its path', () {
      final drive = PathPrefix.parse('/v1.0/drives/d/')!;
      final request = Request(
        origin,
        path: WebPath.parse('/v1.0/drives/d/items/i/content')!,
        grantedPathPrefix: drive,
      );
      expect(request.grantedPathPrefix, drive);
      expect(Request(origin).grantedPathPrefix, isNull);
      expect(
        () => Request(
          origin,
          path: WebPath.parse('/v1.0/drives/other/items')!,
          grantedPathPrefix: drive,
        ),
        throwsArgumentError,
      );
    });
  });

  group('PathPrefix', () {
    PathPrefix prefix(String raw) => PathPrefix.parse(raw)!;
    WebPath path(String raw) => WebPath.parse(raw)!;

    test('accepts a prefix that starts and ends with / and keeps it', () {
      expect(prefix('/v1.0/drives/d/').value, '/v1.0/drives/d/');
      expect(prefix('/').value, '/');
    });

    test('refuses one with no trailing /, a query, or an unsafe path', () {
      for (final raw in [
        '',
        'a/',
        '/a',
        '/a/?x=1/',
        '/a/%2e%2e/',
        '/@evil/',
        '//evil/',
        '/a/%C3/',
        '/a/%ZZ/',
        '/a/%/',
      ]) {
        expect(PathPrefix.parse(raw), isNull, reason: raw);
      }
    });

    test('covers paths under it at a segment boundary', () {
      final drive = prefix('/drives/abc/');
      expect(drive.covers(path('/drives/abc/')), isTrue);
      expect(drive.covers(path('/drives/abc/items/1')), isTrue);
      expect(drive.covers(path('/drives/abc/items?\$top=5')), isTrue);
      expect(drive.covers(path('/drives/abcdef/')), isFalse);
      expect(drive.covers(path('/drives/abc')), isFalse, reason: 'itself');
      expect(drive.covers(path('/drives/')), isFalse);
      expect(drive.covers(path('/other/abc/x')), isFalse);
    });

    test('compares segments canonically, either spelling', () {
      final graph = prefix('/v1.0/drives/d/root:/Shared/');
      expect(
        graph.covers(path('/v1.0/drives/d/root:/Shared/a.docx:/content')),
        isTrue,
      );
      expect(graph.covers(path('/v1.0/drives/d/root%3A/Shared/x')), isTrue);
      final teams = prefix('/amer/v3/conversations/19%3Aabc%40thread.v2/');
      expect(
        teams.covers(path('/amer/v3/conversations/19:abc%40thread.v2/x')),
        isTrue,
      );
      expect(prefix('/a/19:x/'), prefix('/a/19%3Ax/'));
      expect(prefix('/a/19:x/').hashCode, prefix('/a/19%3Ax/').hashCode);
    });

    test('an escaped / stays inside its segment', () {
      expect(prefix('/a/').covers(path('/a%2Fb/c')), isFalse);
      expect(prefix('/a%2Fb/').covers(path('/a/b/c')), isFalse);
      expect(prefix('/a%2Fb/').covers(path('/a%2Fb/c')), isTrue);
    });

    test('does not cover a path whose segment does not decode', () {
      expect(prefix('/a/').covers(path('/a/%C3')), isFalse);
    });

    test('/ is the whole site, root included', () {
      expect(prefix('/').covers(path('/anything/at/all')), isTrue);
      expect(prefix('/').covers(WebPath.root), isTrue);
    });
  });

  group('AddressPrefix', () {
    final teams = Origin.parse('https://smba.trafficmanager.net')!;
    final other = Origin.parse('https://evil.example')!;
    final endpoint = AddressPrefix.of(
      teams,
      PathPrefix.parse('/amer/v3/conversations/c/')!,
    );

    test('covers a path under its prefix on its own origin only', () {
      final reply = WebPath.parse('/amer/v3/conversations/c/activities')!;
      expect(endpoint.covers(teams, reply), isTrue);
      expect(endpoint.covers(other, reply), isFalse);
      expect(
        endpoint.covers(teams, WebPath.parse('/amer/v3/conversations/d/x')!),
        isFalse,
      );
    });

    test('equality is by origin and canonical prefix', () {
      expect(
        endpoint,
        AddressPrefix.of(teams, PathPrefix.parse('/amer/v3/conversations/c/')!),
      );
      expect(
        endpoint,
        isNot(
          AddressPrefix.of(
            other,
            PathPrefix.parse('/amer/v3/conversations/c/')!,
          ),
        ),
      );
    });
  });
}
