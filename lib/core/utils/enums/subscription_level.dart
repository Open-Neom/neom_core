enum SubscriptionLevel {
  basic(1),
  creator(2),
  artist(3),
  professional(4),
  premium(5),
  publish(6);

  final int value;
  const SubscriptionLevel(this.value);

}
