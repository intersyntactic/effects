import 'dart:typed_data';

import 'package:is_sign_in_vocabulary/is_sign_in_vocabulary.dart';
import 'package:is_web_address_vocabulary/is_web_address_vocabulary.dart';

import 'outcome.dart';

/// What a [ProposedRequest] asks of its origin.
enum Method { get, post, put, patch, delete }

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

/// What of a 2xx response's body a [ProposedRequest] asks to keep. Every
/// byte kept is recorded, so the airlock decides on this with the rest of
/// the request.
enum BodyToKeep { none, text, bytes }

/// A web request as a tool or the model proposes it, to [origin]. It
/// carries no grant: the airlock decides it, and only a [GrantedRequest]
/// reaches a [CarriesOutWebRequests].
///
/// [path] is appended to [origin]'s address. [signIn] names who it goes as;
/// null sends under no sign-in. [headers] are [validatedHeaders]: never a
/// credential, which is the sign-in's to add.
final class ProposedRequest {
  ProposedRequest(
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
  /// since the request itself is already in the logbook.
  final String? body;

  /// What of the response's body comes back in [WebResponse.body].
  final BodyToKeep keep;
}

/// A [ProposedRequest] the airlock granted, under [grantedPathPrefix]: what
/// a [CarriesOutWebRequests] is given. Made only by [GrantedRequest.under].
final class GrantedRequest {
  const GrantedRequest._(this.proposed, this.grantedPathPrefix);

  /// [proposed], granted under [grantedPathPrefix] on its origin, or an
  /// [ArgumentError] when that prefix doesn't cover its path. `/` grants
  /// the whole site.
  factory GrantedRequest.under(
    ProposedRequest proposed,
    PathPrefix grantedPathPrefix,
  ) {
    if (!grantedPathPrefix.covers(proposed.path)) {
      throw ArgumentError.value(
        proposed.path.value,
        'proposed.path',
        'is not under the granted prefix $grantedPathPrefix',
      );
    }
    return GrantedRequest._(proposed, grantedPathPrefix);
  }

  final ProposedRequest proposed;

  /// The path prefix on the proposed origin this request was granted
  /// under, which covers its path. A redirect that stays on that origin
  /// must stay under it too; one to another origin is the driver's to
  /// allow as before.
  final PathPrefix grantedPathPrefix;
}

/// A response's body, as its [ProposedRequest.keep] asked.
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

/// The site's response to a [GrantedRequest]: [status], and either
/// [created] (the id the destination made of it, when it made one) or
/// [refusedBecause] (why, in the site's own words, when [status] was not
/// 2xx).
///
/// [body] is what [ProposedRequest.keep] asked for, only for a 2xx [status].
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
