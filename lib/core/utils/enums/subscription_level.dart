enum SubscriptionLevel {
  freemium(0),
  freeMonth(1),
  basic(2),
  creator(3),
  connect(4),
  artist(5),
  professional(6),
  premium(7),
  publish(8),
  platinum(9);

  final int value;
  const SubscriptionLevel(this.value);

}
