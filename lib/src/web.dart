/// An http(s) site a [Request] may be sent to: scheme, host and port only,
/// with no path, query, fragment or credentials. A rule grants or denies by
/// comparing one of these with `==`, so naming a site covers every request
/// to it.
final class Origin {
  const Origin._(this.value);

  /// [raw] as an http(s) site, such as `https://api.example.com`, or null
  /// when it is not one, or carries a path, query, fragment or
  /// credentials.
  static Origin? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return null;
    }
    return Origin._(Uri(scheme: uri.scheme, host: uri.host, port: uri.port));
  }

  final Uri value;

  @override
  bool operator ==(Object other) => other is Origin && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// One of the person's sign-ins, by name, such as `some-bot`. Never the
/// secret: the driver holds that, so it reaches neither a tool nor the
/// record.
final class SignIn {
  const SignIn._(this.name);

  /// [raw] as a sign-in's name, or null unless it is lowercase letters,
  /// digits, `-` and `_`.
  static SignIn? parse(String raw) =>
      _name.hasMatch(raw) ? SignIn._(raw) : null;

  final String name;

  @override
  bool operator ==(Object other) => other is SignIn && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

final _name = RegExp(r'^[a-z0-9][a-z0-9_-]*$');

/// What a [Request] asks of its [origin].
enum Method { get, post, put, patch, delete }

/// A path appended to an [Origin]'s address, never able to change which
/// site is reached: `@evil.example` after `https://a.example` would be a
/// login to `evil.example` if a path could carry an authority of its own.
final class WebPath {
  const WebPath._(this.value);

  static const root = WebPath._('');

  /// [raw] as a path on an origin, or null unless it starts with exactly
  /// one `/` and carries no `..` segment or `@`, each a way a path could
  /// name somewhere other than where it was decided to go.
  static WebPath? parse(String raw) {
    if (!raw.startsWith('/') || raw.startsWith('//')) return null;
    if (raw.contains('..') || raw.contains('@')) return null;
    return WebPath._(raw);
  }

  final String value;

  @override
  bool operator ==(Object other) => other is WebPath && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Whether [name] is a credential header (`authorization`,
/// `proxy-authorization`, `cookie`, `x-api-key`): a sign-in's secret to
/// add, never a tool's or a renderer's to write into the record.
bool isCredentialHeader(String name) =>
    _credentialHeaders.contains(name.toLowerCase());

/// [headers], unmodifiable, or an [ArgumentError] when one of them is
/// [isCredentialHeader]: that is a sign-in's secret to add, so it must
/// never be something a tool wrote and the record kept.
Map<String, String> validatedHeaders(Map<String, String> headers) {
  for (final name in headers.keys) {
    if (isCredentialHeader(name)) {
      throw ArgumentError.value(
        name,
        'headers',
        "carries a credential, which is the sign-in's",
      );
    }
  }
  return Map.unmodifiable(headers);
}

const _credentialHeaders = {
  'authorization',
  'proxy-authorization',
  'cookie',
  'x-api-key',
};

/// Something a [WebDriver] sends to [origin], reaching the world.
///
/// [path] is appended to [origin]'s address. [signIn] names who it goes as;
/// null sends under no sign-in. [headers] are [validatedHeaders]: never a
/// credential, which is the sign-in's to add.
final class Request {
  Request(
    this.origin, {
    this.method = Method.get,
    this.path = WebPath.root,
    this.signIn,
    Map<String, String> headers = const {},
    this.body,
  }) : headers = validatedHeaders(headers);

  final Origin origin;
  final Method method;
  final WebPath path;
  final SignIn? signIn;
  final Map<String, String> headers;

  /// What reaches the destination alone. [Sent] keeps no copy
  /// of it: what a reader needs back — the model's output, the person's
  /// words — is already elsewhere in the record.
  final String? body;
}

/// What a [Request] did: [status], and either [created] (the id the
/// destination made of it, when it made one) or [refusedBecause] (why,
/// when [status] was not 2xx).
///
/// Carries no body: naming what was sent, where it went and what came
/// back is enough, since what it carried is already elsewhere in the
/// record.
final class Sent {
  const Sent({required this.status, this.created, this.refusedBecause});

  final int status;
  final String? created;

  /// Why the destination refused a non-2xx [status], in its own words,
  /// so a reader can say why without reaching into a log only the
  /// driver's host can see. A refused sign-in, where nothing was sent,
  /// is [Refused], not this.
  final String? refusedBecause;
}
