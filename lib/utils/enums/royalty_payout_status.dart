enum RoyaltyPayoutStatus {
  pending(0),
  processing(1),
  completed(2),
  failed(3),
  unclaimed(4);

  final int value;
  const RoyaltyPayoutStatus(this.value);
}
