/// The backend saves scan images as `http://127.0.0.1:8000/uploads/<file>`. On a phone,
/// 127.0.0.1 is the phone itself, so point those at the API server instead.
String resolveMediaUrl(String url, String apiBaseUrl) {
  if (url.isEmpty) return url;
  final uri = Uri.tryParse(url);
  final api = Uri.tryParse(apiBaseUrl);
  if (uri == null || api == null) return url;
  if (uri.host != '127.0.0.1' && uri.host != 'localhost') return url;
  // api.port is the scheme default (443/80) when none is written; Uri omits it again in toString().
  return uri.replace(scheme: api.scheme, host: api.host, port: api.port).toString();
}
