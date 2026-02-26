import 'package:enum_to_string/enum_to_string.dart';

enum WithdrawalStatus {
  pending(0),
  processing(1),
  completed(2),
  rejected(3);

  final int value;
  const WithdrawalStatus(this.value);
}

class WithdrawalRequest {

  String id;
  String ownerEmail;
  double appCoinsAmount;       /// Amount in AppCoins to withdraw
  double mxnAmount;            /// Equivalent in MXN
  String bankClabe;            /// CLABE interbancaria
  WithdrawalStatus status;
  int createdTime;
  int processedTime;
  String adminNote;            /// Note from admin if rejected

  @override
  String toString() {
    return 'WithdrawalRequest{id: $id, ownerEmail: $ownerEmail, '
        'appCoinsAmount: $appCoinsAmount, mxnAmount: $mxnAmount, '
        'status: $status}';
  }

  WithdrawalRequest({
    this.id = '',
    this.ownerEmail = '',
    this.appCoinsAmount = 0.0,
    this.mxnAmount = 0.0,
    this.bankClabe = '',
    this.status = WithdrawalStatus.pending,
    this.createdTime = 0,
    this.processedTime = 0,
    this.adminNote = '',
  });

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'ownerEmail': ownerEmail,
      'appCoinsAmount': appCoinsAmount,
      'mxnAmount': mxnAmount,
      'bankClabe': bankClabe,
      'status': status.name,
      'createdTime': createdTime,
      'processedTime': processedTime,
      'adminNote': adminNote,
    };
  }

  factory WithdrawalRequest.fromJSON(dynamic json) {
    return WithdrawalRequest(
      id: json['id'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      appCoinsAmount: (json['appCoinsAmount'] ?? 0).toDouble(),
      mxnAmount: (json['mxnAmount'] ?? 0).toDouble(),
      bankClabe: json['bankClabe'] ?? '',
      status: EnumToString.fromString(
        WithdrawalStatus.values,
        json['status']?.toString() ?? 'pending',
      ) ?? WithdrawalStatus.pending,
      createdTime: json['createdTime'] ?? 0,
      processedTime: json['processedTime'] ?? 0,
      adminNote: json['adminNote'] ?? '',
    );
  }
}
