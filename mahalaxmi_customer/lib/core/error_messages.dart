class CustomerErrorMessages {
  static String fromError(Object error) {
    final message = error.toString();

    if (_containsAny(message, [
      'SocketException',
      'Failed host lookup',
      'No address associated with hostname',
      'Connection refused',
      'Connection timed out',
      'Network is unreachable',
      'No route to host',
    ])) {
      return 'No internet connection. Please check your mobile data or Wi-Fi and try again.';
    }

    if (_containsAny(message, [
      'TimeoutException',
      'timed out',
      'timeout',
    ])) {
      return 'The connection is slow. Please try again.';
    }

    if (_containsAny(message, [
      'ClientException',
      'PostgrestException',
      'RepositoryException',
      'Supabase',
      'supabase',
      'rate_list',
      'rest/v1',
      '400 Bad Request',
      '500 Internal Server Error',
      '502 Bad Gateway',
      '503 Service Unavailable',
    ])) {
      return 'Could not load data. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String networkOrFallback(Object error) {
    final message = error.toString();
    if (_containsAny(message, [
      'SocketException',
      'Failed host lookup',
      'No address associated with hostname',
      'Connection refused',
      'Connection timed out',
      'Network is unreachable',
      'No route to host',
      'TimeoutException',
      'timed out',
      'timeout',
    ])) {
      return 'No internet connection. Please check your mobile data or Wi-Fi and try again.';
    }
    return 'Could not load data. Please try again.';
  }

  static bool _containsAny(String message, List<String> patterns) {
    return patterns.any((p) => message.contains(p));
  }
}
