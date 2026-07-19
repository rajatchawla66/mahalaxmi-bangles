class RepositoryException implements Exception {
  final String message;
  final String? tableName;
  final Object? originalError;

  const RepositoryException(
    this.message, {
    this.tableName,
    this.originalError,
  });

  @override
  String toString() {
    final buf = StringBuffer('RepositoryException');
    if (tableName != null) buf.write('[$tableName]');
    buf.write(': $message');
    return buf.toString();
  }
}

class NotFoundException extends RepositoryException {
  const NotFoundException(
    super.message, {
    super.tableName,
    super.originalError,
  });
}
