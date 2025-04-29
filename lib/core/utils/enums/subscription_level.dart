enum SubscriptionLevel {
  freemium(0),
  basic(1),
  creator(2),
  connect(3),
  artist(4),
  professional(5),
  premium(6),
  publish(7),
  platinum(8);

  final int value;
  const SubscriptionLevel(this.value);

}
