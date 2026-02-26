import 'package:enum_to_string/enum_to_string.dart';

import '../../../utils/enums/royalty_payout_status.dart';

class RoyaltyPayout {

  String id;
  String ownerEmail;
  int month;
  int year;
  int totalNupale;              /// Pages read on creator's works this month
  int platformTotalNupale;      /// Total pages read on platform this month
  double valuePerPage;          /// MXN value per page this month
  double grossAmountMxn;        /// totalNupale × valuePerPage
  double appCoinsDeposited;     /// AppCoins credited to creator wallet
  int activeSubscriptions;      /// Active basic subscriptions this month
  String transactionId;         /// Reference to AppTransaction created
  RoyaltyPayoutStatus status;
  int createdTime;
  Map<String, int> itemBreakdown; /// itemId → pages read (per-work breakdown)

  @override
  String toString() {
    return 'RoyaltyPayout{id: $id, ownerEmail: $ownerEmail, month: $month, year: $year, '
        'totalNupale: $totalNupale, grossAmountMxn: $grossAmountMxn, '
        'appCoinsDeposited: $appCoinsDeposited, status: $status}';
  }

  RoyaltyPayout({
    this.id = '',
    this.ownerEmail = '',
    this.month = 0,
    this.year = 0,
    this.totalNupale = 0,
    this.platformTotalNupale = 0,
    this.valuePerPage = 0.0,
    this.grossAmountMxn = 0.0,
    this.appCoinsDeposited = 0.0,
    this.activeSubscriptions = 0,
    this.transactionId = '',
    this.status = RoyaltyPayoutStatus.pending,
    this.createdTime = 0,
    this.itemBreakdown = const {},
  });

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'ownerEmail': ownerEmail,
      'month': month,
      'year': year,
      'totalNupale': totalNupale,
      'platformTotalNupale': platformTotalNupale,
      'valuePerPage': valuePerPage,
      'grossAmountMxn': grossAmountMxn,
      'appCoinsDeposited': appCoinsDeposited,
      'activeSubscriptions': activeSubscriptions,
      'transactionId': transactionId,
      'status': status.name,
      'createdTime': createdTime,
      'itemBreakdown': itemBreakdown,
    };
  }

  factory RoyaltyPayout.fromJSON(dynamic json) {
    return RoyaltyPayout(
      id: json['id'] ?? '',
      ownerEmail: json['ownerEmail'] ?? '',
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      totalNupale: json['totalNupale'] ?? 0,
      platformTotalNupale: json['platformTotalNupale'] ?? 0,
      valuePerPage: (json['valuePerPage'] ?? 0).toDouble(),
      grossAmountMxn: (json['grossAmountMxn'] ?? 0).toDouble(),
      appCoinsDeposited: (json['appCoinsDeposited'] ?? 0).toDouble(),
      activeSubscriptions: json['activeSubscriptions'] ?? 0,
      transactionId: json['transactionId'] ?? '',
      status: EnumToString.fromString(
        RoyaltyPayoutStatus.values,
        json['status']?.toString() ?? 'pending',
      ) ?? RoyaltyPayoutStatus.pending,
      createdTime: json['createdTime'] ?? 0,
      itemBreakdown: (json['itemBreakdown'] != null)
          ? (json['itemBreakdown'] as Map).map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()))
          : {},
    );
  }
}
