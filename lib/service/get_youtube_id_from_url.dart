String? getYoutubeIdFromUrl(String url) {
  const youtubeComHosts = ['youtube.com', 'www.youtube.com', 'm.youtube.com'];

  if (url.contains(' ')) {
    return null;
  }

  late final Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (e) {
    return null;
  }

  if (!['https', 'http'].contains(uri.scheme)) {
    return null;
  }

  // youtube.com/watch?v=xxxxxxxxxxx
  if (youtubeComHosts.contains(uri.host) &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == 'watch' &&
      uri.queryParameters.containsKey('v')) {
    final videoId = uri.queryParameters['v']!;
    return _isValidId(videoId) ? videoId : null;
  }

  // youtu.be/xxxxxxxxxxx
  if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
    final videoId = uri.pathSegments.first;
    return _isValidId(videoId) ? videoId : null;
  }

  // youtube.com/shorts/xxxxxxxxxxx
  // youtube.com/embed/xxxxxxxxxxx
  // youtube.com/live/xxxxxxxxxxx
  if (youtubeComHosts.contains(uri.host) &&
      uri.pathSegments.length == 2 &&
      ['shorts', 'embed', 'live'].contains(uri.pathSegments.first)) {
    final videoId = uri.pathSegments[1];
    return _isValidId(videoId) ? videoId : null;
  }

  return null;
}

bool _isValidId(String id) => RegExp(r'^[_\-a-zA-Z0-9]{11}$').hasMatch(id);
