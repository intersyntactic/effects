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
/// logbook.
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

  /// [raw] as a path on an origin, optionally with a `?` query, or null
  /// unless it is exactly what is sent: it starts with exactly one `/`,
  /// carries no `..`, `@` or `#`, no `%25` that a second decode would turn
  /// into an escaped `.`, `/`, `\` or `%`, and a URI parser leaves its path
  /// and query byte for byte as they are.
  ///
  /// A parser collapses `%2e%2e`, `.%2E` and `./` segments, so a path
  /// decided as `/a/%2e%2e/b` would be sent as `/b`. `%252e%252e` passes
  /// through a parser unchanged and becomes `..` at a server that decodes
  /// twice; its `2e` is plain text to the parser, so it is refused in
  /// either case. Any other `%25`, such as `50%25.docx`, is an ordinary
  /// `%`. Escapes must be uppercase hex (`%2F`, not
  /// `%2f`) and unreserved characters must not be escaped (`.`, not
  /// `%2E`), since a parser rewrites both: `Uri.encodeComponent` produces
  /// escapes that pass.
  static WebPath? parse(String raw) {
    if (!raw.startsWith('/') || raw.startsWith('//')) return null;
    if (raw.contains('..') ||
        raw.contains('@') ||
        raw.contains(_decodesTwiceToStructure) ||
        raw.contains('#')) {
      return null;
    }
    final queryAt = raw.indexOf('?');
    final path = queryAt < 0 ? raw : raw.substring(0, queryAt);
    final query = queryAt < 0 ? null : raw.substring(queryAt + 1);
    final parsed = Uri.tryParse('$_anyOrigin$raw');
    if (parsed == null ||
        parsed.path != path ||
        parsed.hasQuery != (query != null) ||
        (query != null && parsed.query != query)) {
      return null;
    }
    return WebPath._(raw);
  }

  // The origin doesn't change how an http(s) path or query parses.
  static const _anyOrigin = 'https://origin.invalid';

  static final _decodesTwiceToStructure = RegExp(
    '%25(2e|2f|5c|25)',
    caseSensitive: false,
  );

  final String value;

  @override
  bool operator ==(Object other) => other is WebPath && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// The start of the paths something may reach on an origin, such as a
/// Teams conversation's `/amer/v3/conversations/19%3Aabc%40thread.v2/`.
///
/// It is compared by canonical segments: each segment is decoded and
/// encoded again with [Uri.encodeComponent], so `19:` and `19%3A` are the
/// same segment, while a request is still sent exactly as written.
/// RFC 3986 doesn't promise `:` and `%3A` name the same resource, so a
/// server that told them apart could have two sibling resources whose
/// names differ only in encoding. Neither can be at another depth, since
/// `%2F` stays inside its segment and only a literal `/` splits segments.
final class PathPrefix {
  const PathPrefix._(this.value, this._segments);

  /// [raw] as a path prefix, or null unless it starts and ends with `/`,
  /// carries no `?`, is a valid [WebPath], and every segment decodes. `/`
  /// alone is the whole site.
  static PathPrefix? parse(String raw) {
    if (!raw.endsWith('/') || raw.contains('?')) return null;
    if (WebPath.parse(raw) == null) return null;
    final segments = raw == '/'
        ? const <String>[]
        : _canonicalSegments(raw.substring(1, raw.length - 1));
    return segments == null ? null : PathPrefix._(raw, segments);
  }

  final String value;
  final List<String> _segments;

  /// Whether [path], without its query, lies under this prefix: its
  /// canonical segments start with this prefix's and go further, so
  /// `/drives/abc/` covers `/drives/abc/` and `/drives/abc/x` but neither
  /// `/drives/abc` nor `/drives/abcdef/`. False when a segment of [path]
  /// doesn't decode.
  bool covers(WebPath path) {
    final queryAt = path.value.indexOf('?');
    final raw = queryAt < 0 ? path.value : path.value.substring(0, queryAt);
    final segments = _canonicalSegments(raw.isEmpty ? '' : raw.substring(1));
    if (segments == null || segments.length <= _segments.length) return false;
    for (var i = 0; i < _segments.length; i++) {
      if (segments[i] != _segments[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is PathPrefix && other._segments.join('/') == _segments.join('/');

  @override
  int get hashCode => _segments.join('/').hashCode;

  @override
  String toString() => value;
}

/// [joined]'s `/`-separated segments, each decoded and encoded again with
/// [Uri.encodeComponent], or null when one isn't UTF-8. [joined] is from a
/// [WebPath], so every escape in it is well formed.
List<String>? _canonicalSegments(String joined) {
  final canonical = <String>[];
  for (final segment in joined.split('/')) {
    try {
      canonical.add(Uri.encodeComponent(Uri.decodeComponent(segment)));
    } on FormatException {
      return null;
    }
  }
  return canonical;
}

/// The start of the web addresses something may reach: an [origin] and a
/// [pathPrefix] on it, such as where a trajectory's replies go or how far
/// a fetch grant reaches.
final class AddressPrefix {
  const AddressPrefix._(this.origin, this.pathPrefix);

  factory AddressPrefix.of(Origin origin, PathPrefix pathPrefix) =>
      AddressPrefix._(origin, pathPrefix);

  final Origin origin;
  final PathPrefix pathPrefix;

  /// Whether a request to [path] on [to] lies under this prefix.
  bool covers(Origin to, WebPath path) =>
      to == origin && pathPrefix.covers(path);

  @override
  bool operator ==(Object other) =>
      other is AddressPrefix &&
      other.origin == origin &&
      other.pathPrefix == pathPrefix;

  @override
  int get hashCode => Object.hash(origin, pathPrefix);

  @override
  String toString() => '$origin$pathPrefix';
}

/// Whether [name] is a credential header (`authorization`,
/// `proxy-authorization`, `cookie`, `x-api-key`): a sign-in's secret to
/// add, never a tool's or a renderer's to write into the logbook.
bool isCredentialHeader(String name) =>
    _credentialHeaders.contains(name.toLowerCase());

/// [headers], unmodifiable, or an [ArgumentError] when one of them is
/// [isCredentialHeader]: that is a sign-in's secret to add, so it must
/// never be something a tool wrote and the logbook kept.
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
    this.grantedPathPrefix,
  }) : headers = validatedHeaders(headers) {
    if (grantedPathPrefix case final prefix? when !prefix.covers(path)) {
      throw ArgumentError.value(
        path.value,
        'path',
        'is not under the granted prefix $prefix',
      );
    }
  }

  final Origin origin;
  final Method method;
  final WebPath path;
  final SignIn? signIn;
  final Map<String, String> headers;

  /// What reaches the destination. [WebResponse] keeps no copy of it,
  /// since the request itself is already in the logbook.
  final String? body;

  /// What of the response's body comes back in [WebResponse.body].
  final BodyToKeep keep;

  /// The path prefix on [origin] this request was granted under, which
  /// covers [path]. A redirect that stays on [origin] must stay under it
  /// too; one to another origin is the driver's to allow as before. Null
  /// when the grant bounds no path.
  final PathPrefix? grantedPathPrefix;
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
/// carries its token in the query and the logbook must never hold it.
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
