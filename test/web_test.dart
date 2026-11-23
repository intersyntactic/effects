import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

void main() {
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

  group('ProposedRequest', () {
    final origin = Origin.parse('https://api.example.com')!;

    test('defaults path to WebPath.root', () {
      expect(ProposedRequest(origin).path, WebPath.root);
    });

    test('refuses a header carrying a credential', () {
      expect(
        () => ProposedRequest(origin, headers: const {'authorization': 'x'}),
        throwsArgumentError,
      );
    });
  });

  group('GrantedRequest', () {
    final origin = Origin.parse('https://api.example.com')!;
    final drive = PathPrefix.parse('/v1.0/drives/d/')!;

    test('grants a proposal under a prefix that covers its path', () {
      final proposed = ProposedRequest(
        origin,
        path: WebPath.parse('/v1.0/drives/d/items/i/content')!,
      );
      final granted = GrantedRequest.under(proposed, drive);
      expect(granted.proposed, same(proposed));
      expect(granted.grantedPathPrefix, drive);
    });

    test('refuses a prefix that does not cover the path', () {
      expect(
        () => GrantedRequest.under(
          ProposedRequest(origin, path: WebPath.parse('/v1.0/drives/x/a')!),
          drive,
        ),
        throwsArgumentError,
      );
    });

    test('/ grants the whole site, root included', () {
      final site = PathPrefix.parse('/')!;
      expect(
        GrantedRequest.under(ProposedRequest(origin), site).grantedPathPrefix,
        site,
      );
    });
  });
}
