import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/app_currency.dart';
import '../../utils/enums/wallet_status.dart';

class Wallet {

  String id = "";
  double balance = 0.0;
  AppCurrency currency;

  WalletStatus status;
  int createdTime;
  int lastUpdated;
  String? lastTransactionId;

  Wallet({
    this.id = '',
    this.balance = 0.0,
    this.currency = AppCurrency.appCoin, // Valor por defecto
    this.status = WalletStatus.active,   // Valor por defecto
    this.createdTime = 0, // Debería establecerse al crear con DateTime.now().millisecondsSinceEpoch
    this.lastUpdated = 0, // Debería establecerse al crear y actualizar
    this.lastTransactionId, // Opcional
  });

  Map<String, dynamic> toJSON() {
    return {
      'id': id, // Aunque el ID del documento es el mismo, guardarlo puede ser útil.
      'balance': balance,
      'currency': currency.name,
      'status': status.name,
      'createdTime': createdTime,
      'lastUpdated': lastUpdated,
      'lastTransactionId': lastTransactionId,
    };
  }

  static double _parseFiniteBalance(dynamic raw) {
    if (raw is num) {
      final d = raw.toDouble();
      return d.isFinite ? d : 0.0;
    }
    if (raw is String) {
      final d = double.tryParse(raw.trim());
      if (d != null && d.isFinite) return d;
    }
    return 0.0;
  }

  static WalletStatus _parseWalletStatus(dynamic raw) {
    if (raw == null) return WalletStatus.active;
    final text = raw.toString().trim();
    if (text.isEmpty) return WalletStatus.active;
    final parsed = EnumToString.fromString(WalletStatus.values, text);
    // Fail-closed when an explicit status field is present but unrecognized/corrupted.
    return parsed ?? WalletStatus.suspended;
  }

  static int _parseFiniteInt(dynamic raw) {
    if (raw is num) {
      return raw.isFinite ? raw.toInt() : 0;
    }
    if (raw is String) {
      return int.tryParse(raw.trim()) ?? 0;
    }
    return 0;
  }

  Wallet.fromJSON(Map<dynamic, dynamic> data)
      : id = data["id"]?.toString() ?? "",
        balance = _parseFiniteBalance(data["balance"]),
        currency = EnumToString.fromString(AppCurrency.values, data["currency"]?.toString() ?? "") ?? AppCurrency.appCoin,
        status = _parseWalletStatus(data["status"]),
        createdTime = _parseFiniteInt(data["createdTime"]),
        lastUpdated = _parseFiniteInt(data["lastUpdated"]),
        lastTransactionId = data["lastTransactionId"]?.toString();

}
