/// Error yang pesannya aman ditampilkan langsung ke pengguna.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}
