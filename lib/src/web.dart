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

/// Something a [WebDriver] sends out of the home, to [origin].
///
/// [path] is appended to [origin]'s address. [signIn] names who it goes as;
/// null sends under no sign-in. [headers] never carry a credential: the
/// sign-in's secret is the driver's to add, so a request naming
/// `authorization`, `proxy-authorization`, `cookie` or `x-api-key` is an
/// [ArgumentError].
final class Request {
  Request(
    this.origin, {
    this.method = Method.get,
    this.path = '',
    this.signIn,
    Map<String, String> headers = const {},
    this.body,
  }) : headers = Map.unmodifiable(headers) {
    for (final name in headers.keys) {
      if (_credentialHeaders.contains(name.toLowerCase())) {
        throw ArgumentError.value(
          name,
          'headers',
          "carries a credential, which is the sign-in's",
        );
      }
    }
  }

  final Origin origin;
  final Method method;
  final String path;
  final SignIn? signIn;
  final Map<String, String> headers;

  /// What leaves the home, for the destination alone. [Sent] keeps no copy
  /// of it: what a reader needs back — the model's output, the person's
  /// words — is already elsewhere in the record.
  final String? body;
}

const _credentialHeaders = {
  'authorization',
  'proxy-authorization',
  'cookie',
  'x-api-key',
};

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
