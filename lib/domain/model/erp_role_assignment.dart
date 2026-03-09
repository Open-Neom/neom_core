import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/erp_privilege.dart';

/// Maps a user to their ERP privileges and executive title.
/// Stored in Firestore `erpRoleAssignments` collection, keyed by userId.
class ErpRoleAssignment {

  String userId;
  String displayName;          // "COO", "CCO", "CEO"
  List<ErpPrivilege> privileges;
  int assignedDate;
  String assignedBy;           // superAdmin who granted access

  ErpRoleAssignment({
    this.userId = '',
    this.displayName = '',
    this.privileges = const [],
    this.assignedDate = 0,
    this.assignedBy = '',
  });

  bool hasPrivilege(ErpPrivilege privilege) => privileges.contains(privilege);

  bool get canViewKpis => hasPrivilege(ErpPrivilege.viewFinancialKpis);
  bool get canManageSubscriptions => hasPrivilege(ErpPrivilege.manageSubscriptionStatus);
  bool get canViewPayments => hasPrivilege(ErpPrivilege.viewPaymentHistory);
  bool get canExportForecast => hasPrivilege(ErpPrivilege.exportRevenueForecast);

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'userId': userId,
      'displayName': displayName,
      'privileges': privileges.map((p) => p.name).toList(),
      'assignedDate': assignedDate,
      'assignedBy': assignedBy,
    };
  }

  ErpRoleAssignment.fromJSON(Map<String, dynamic> data)
      : userId = data['userId'] ?? '',
        displayName = data['displayName'] ?? '',
        privileges = (data['privileges'] as List<dynamic>?)
            ?.map((p) => EnumToString.fromString(ErpPrivilege.values, p.toString()))
            .whereType<ErpPrivilege>()
            .toList() ?? [],
        assignedDate = data['assignedDate'] ?? 0,
        assignedBy = data['assignedBy'] ?? '';
}
