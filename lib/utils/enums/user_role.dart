///User Roles for administration porpuses
enum UserRole {
  subscriber(0),
  editor(1),
  support(2),
  developer(3),
  admin(4),
  superAdmin(5);

  final int value;

  const UserRole(this.value);
}
