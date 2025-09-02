// lib/core/message_generator.dart

import 'diameter_avp.dart';

/// Base class for all declarative message definitions.
abstract class MessageGenerator {
  /// Converts the properties of the subclass into a List of AVPs.
  List<AVP> toAVPs();
}