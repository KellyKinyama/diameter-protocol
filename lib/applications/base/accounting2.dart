// lib/applications/base/accounting.dart

import '../../core/avp_dictionary.dart';
import '../../core/diameter_avp.dart';
import '../../core/message_generator.dart';

class AccountingRequest extends MessageGenerator {
  String sessionId;
  int accountingRecordType;
  int accountingRecordNumber;

  AccountingRequest({
    required this.sessionId,
    required this.accountingRecordType,
    required this.accountingRecordNumber,
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_ACCOUNTING_RECORD_TYPE, accountingRecordType),
      AVP.fromValue(AVP_ACCOUNTING_RECORD_NUMBER, accountingRecordNumber),
    ];
  }
}

class AccountingAnswer extends MessageGenerator {
  String sessionId;
  int accountingRecordType;
  int accountingRecordNumber;

  AccountingAnswer({
    required this.sessionId,
    required this.accountingRecordType,
    required this.accountingRecordNumber,
  });

  @override
  List<AVP> toAVPs() {
    return [
      AVP.fromValue(AVP_SESSION_ID, sessionId),
      AVP.fromValue(AVP_ACCOUNTING_RECORD_TYPE, accountingRecordType),
      AVP.fromValue(AVP_ACCOUNTING_RECORD_NUMBER, accountingRecordNumber),
    ];
  }
}
