class SmartschoolBridgeException implements Exception {
  SmartschoolBridgeException(this.message);
  final String message;

  @override
  String toString() => 'SmartschoolBridgeException: $message';
}
