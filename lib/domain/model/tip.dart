import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/tip_tier.dart';

class Tip {

  String id;
  String senderId;
  String senderName;
  String senderAvatarUrl;
  String recipientId;
  String recipientName;
  TipTier tier;
  double amount;
  String? message;
  String? contextType; // 'live', 'profile', 'post'
  String? contextId;   // ID of the live session, post, etc.
  int createdTime;

  Tip({
    this.id = '',
    this.senderId = '',
    this.senderName = '',
    this.senderAvatarUrl = '',
    this.recipientId = '',
    this.recipientName = '',
    this.tier = TipTier.cafe,
    this.amount = 0,
    this.message,
    this.contextType,
    this.contextId,
    this.createdTime = 0,
  });

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'tier': tier.name,
      'amount': amount,
      'message': message,
      'contextType': contextType,
      'contextId': contextId,
      'createdTime': createdTime,
    };
  }

  Tip.fromJSON(dynamic data)
      : id = data['id'] ?? '',
        senderId = data['senderId'] ?? '',
        senderName = data['senderName'] ?? '',
        senderAvatarUrl = data['senderAvatarUrl'] ?? '',
        recipientId = data['recipientId'] ?? '',
        recipientName = data['recipientName'] ?? '',
        tier = EnumToString.fromString(
            TipTier.values, data['tier'] ?? TipTier.cafe.name) ?? TipTier.cafe,
        amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0,
        message = data['message'],
        contextType = data['contextType'],
        contextId = data['contextId'],
        createdTime = data['createdTime'] ?? 0;

  @override
  String toString() {
    return 'Tip{id: $id, senderId: $senderId, senderName: $senderName, '
        'recipientId: $recipientId, recipientName: $recipientName, '
        'tier: $tier, amount: $amount, message: $message}';
  }
}
