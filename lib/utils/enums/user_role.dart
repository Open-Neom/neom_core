///User Roles for administration purposes
enum UserRole {
  subscriber(0),
  editor(1),
  support(2),
  /// ERP / Laboral — financial monitoring and business intelligence access
  erp(3),
  developer(4),
  admin(5),
  superAdmin(6);

  final int value;

  const UserRole(this.value);
}
