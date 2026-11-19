import 'dart:typed_data';

import 'outcome.dart';

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

/// What of a 2xx response's body a [Request] asks to keep. Every byte kept
/// is recorded, so the airlock decides on this with the rest of the request.
enum BodyToKeep { none, text, bytes }

/// Something a [CarriesOutWebRequests] carries out to [origin], reaching
/// the world.
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
    this.keep = BodyToKeep.none,
  }) : headers = validatedHeaders(headers);

  final Origin origin;
  final Method method;
  final WebPath path;
  final SignIn? signIn;
  final Map<String, String> headers;

  /// What reaches the destination. [WebResponse] keeps no copy of it,
  /// since the request itself is already in the record.
  final String? body;

  /// What of the response's body comes back in [WebResponse.body].
  final BodyToKeep keep;
}

/// A response's body, as its [Request.keep] asked.
sealed class ResponseBody {
  const ResponseBody();
}

/// Nothing kept: [BodyToKeep.none] was asked, or [WebResponse.status] was
/// not 2xx.
final class NoBody extends ResponseBody {
  const NoBody();
}

/// The body decoded as UTF-8, a leading byte order mark included, for
/// [BodyToKeep.text].
final class TextBody extends ResponseBody {
  const TextBody(this.text);

  final String text;
}

/// The body's exact bytes, such as a .docx's zip, for [BodyToKeep.bytes].
final class BytesBody extends ResponseBody {
  const BytesBody(this.bytes);

  final Uint8List bytes;
}

/// Where a followed redirect ended up: an http(s) address with no query,
/// fragment or credentials, since a pre-authenticated download address
/// carries its token in the query and the record must never hold it.
final class RedirectedTo {
  const RedirectedTo._(this.value);

  /// [address] with its query, fragment and credentials dropped, or null
  /// when it is not an http(s) address.
  static RedirectedTo? of(Uri address) {
    final site = Uri(
      scheme: address.scheme,
      host: address.host,
      port: address.port,
    );
    if (Origin.parse(site.toString()) == null) return null;
    return RedirectedTo._(site.replace(path: address.path));
  }

  /// [raw] as a recorded redirect, or null unless it is already an http(s)
  /// address with no query, fragment or credentials.
  static RedirectedTo? parse(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return of(uri);
  }

  final Uri value;

  @override
  bool operator ==(Object other) =>
      other is RedirectedTo && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// The site's response to a [Request]: [status], and either [created] (the
/// id the destination made of it, when it made one) or [refusedBecause]
/// (why, in the site's own words, when [status] was not 2xx).
///
/// [body] is what [Request.keep] asked for, only for a 2xx [status].
/// [redirects] are the hops the driver followed to reach the response. A
/// refused sign-in, where nothing was sent, is [Refused], not this.
final class WebResponse {
  const WebResponse({
    required this.status,
    this.created,
    this.refusedBecause,
    this.body = const NoBody(),
    this.redirects = const [],
  });

  final int status;
  final String? created;

  /// Why the destination refused a non-2xx [status], in its own words,
  /// so a reader can say why without reaching into a log only the
  /// driver's host can see.
  final String? refusedBecause;

  final ResponseBody body;

  /// Each address a followed redirect led to, in order, the last being
  /// where [status] and [body] came from. Empty when none was followed.
  final List<RedirectedTo> redirects;
}
