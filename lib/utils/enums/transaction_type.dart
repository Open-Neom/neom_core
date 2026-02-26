enum TransactionType {
  deposit(0), //AppBank to user
  coupon(1), //AppBank to user
  loyaltyPoints(2), //AppBank to User
  refund(3), //AppBank to user

  withdrawal(4), //User to App Bank
  purchase(5), //User to AppBank
  transfer(6), //User to User
  tip(7), //User to User (with tier + message)
  royaltyPayout(8); //AppBank to User (NUPALE royalty distribution)

  final int value;
  const TransactionType(this.value);
}
