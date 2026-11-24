import 'package:is_effects/is_effects.dart' as effects;
import 'package:is_model_vocabulary/is_model_vocabulary.dart' as model;
import 'package:is_sign_in_vocabulary/is_sign_in_vocabulary.dart' as sign_in;
import 'package:is_web_address_vocabulary/is_web_address_vocabulary.dart'
    as vocabulary;
import 'package:test/test.dart';

void main() {
  test('SignIn is the sign-in vocabulary\'s own, not a copy', () {
    expect(effects.SignIn, same(sign_in.SignIn));
    expect(
      effects.decodeSignIn(
        sign_in.encodeSignIn(sign_in.SignIn.parse('a-bot')!),
      ),
      sign_in.SignIn.parse('a-bot'),
    );
  });

  test('the model replies are the model vocabulary\'s own, not copies', () {
    expect(effects.ModelReply, same(model.ModelReply));
    expect(effects.ProposedToolCalls, same(model.ProposedToolCalls));
    expect(effects.ModelUsage, same(model.ModelUsage));
    expect(effects.ToolCall, same(model.ToolCall));
    final reply = effects.decodeModelReply(
      model.ProposedToolCalls(
        text: '',
        calls: [
          model.ToolCall(
            id: model.ToolCallId.parse('toolu_1')!,
            name: model.CalledToolName.fromSent('Read'),
            input: model.ToolInput.parse('{}')!,
          ),
        ],
      ).toJson(),
    );
    expect(reply, isA<model.ProposedToolCalls>());
  });

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
