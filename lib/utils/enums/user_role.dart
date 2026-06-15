///User Roles for administration purposes
enum UserRole {
  subscriber(0),
  editor(1),
  support(2),
  /// ERP / Laboral — financial monitoring and business intelligence access
  erp(3),
  pos(4),
  developer(5),
  admin(6),
  superAdmin(7);

  final int value;

  const UserRole(this.value);
}
