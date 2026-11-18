import 'package:flutter/widgets.dart';

import '../../utils/enums/tip_tier.dart';
import '../model/tip.dart';

abstract class TipService {
  Future<void> showTipModal(
    BuildContext context, {
    required String recipientId,
    required String recipientName,
    String? contextType,
    String? contextId,
  }) async {}

  Future<bool> sendTip({
    required String recipientId,
    required TipTier tier,
    String? message,
    String? contextType,
    String? contextId,
  });

  Future<List<Tip>> getTopSupporters(String recipientId, {int limit = 10});

  Future<List<Tip>> getTipsForProfile(String recipientId, {int limit = 20});

  Future<List<Tip>> getTipsSentBy(String senderId, {int limit = 20});

  Future<double> getTotalTipsReceived(String recipientId);
}
