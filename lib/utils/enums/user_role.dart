///User Roles for administration porpuses
enum UserRole {
  subscriber(0),
  editor(1),
  admin(2),
  superAdmin(3);

  final int value;

  const UserRole(this.value);
}
