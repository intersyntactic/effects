import 'package:is_effects/is_effects.dart' as effects;
import 'package:is_web_address_vocabulary/is_web_address_vocabulary.dart'
    as vocabulary;
import 'package:test/test.dart';

void main() {
  test('the web address types are the vocabulary\'s own, not copies', () {
    expect(effects.Origin, same(vocabulary.Origin));
    expect(effects.WebPath, same(vocabulary.WebPath));
    expect(effects.PathPrefix, same(vocabulary.PathPrefix));
    expect(effects.AddressPrefix, same(vocabulary.AddressPrefix));
  });

  test('an AddressPrefix from one decodes as the other', () {
    final prefix = vocabulary.AddressPrefix.of(
      vocabulary.Origin.parse('https://smba.trafficmanager.net')!,
      vocabulary.PathPrefix.parse('/amer/v3/conversations/19%3Aabc/')!,
    );
    final effects.AddressPrefix decoded = effects.decodeAddressPrefix(
      vocabulary.encodeAddressPrefix(prefix),
    );
    expect(decoded, prefix);
  });
}
