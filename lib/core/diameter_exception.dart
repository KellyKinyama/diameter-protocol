// lib/core/diameter_exception.dart

/// Base class for all Diameter-related exceptions.
class DiameterException implements Exception {
  final String message;
  DiameterException(this.message);

  @override
  String toString() => 'DiameterException: $message';
}

/// Thrown when an AVP's data cannot be decoded into the expected type.
class AVPDecodeException extends DiameterException {
  AVPDecodeException(String message) : super(message);
}

/// Thrown when a value cannot be encoded into an AVP's data format.
class AVPEncodeException extends DiameterException {
  AVPEncodeException(String message) : super(message);
}
