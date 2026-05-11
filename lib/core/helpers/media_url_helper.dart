import '../networking/api_constants.dart';

String get _mediaOrigin {
  final apiUri = Uri.parse(ApiConstants.apiBaseUrl);

  final scheme = apiUri.scheme.isEmpty ? 'http' : apiUri.scheme;
  final host = apiUri.host.isEmpty ? apiUri.path : apiUri.host;

  return Uri(
    scheme: scheme,
    host: host,
    port: ApiConstants.mediaPort,
  ).toString();
}

String? resolveMediaUrl(String? rawUrl) {
  if (rawUrl == null) {
    return null;
  }

  final normalized = rawUrl.trim();
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      return normalized;
    }

    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final suffix = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      return _buildAbsoluteUrl(suffix);
    }

    return normalized;
  }

  if (normalized.startsWith('localhost') ||
      normalized.startsWith('127.0.0.1')) {
    final firstSlash = normalized.indexOf('/');
    final suffix = firstSlash == -1 ? '' : normalized.substring(firstSlash);
    return _buildAbsoluteUrl(suffix);
  }

  return _buildAbsoluteUrl(normalized);
}

String _buildAbsoluteUrl(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$_mediaOrigin$normalizedPath';
}
