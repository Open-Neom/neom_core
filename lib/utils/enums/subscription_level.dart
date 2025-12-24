enum SubscriptionLevel {
  freemium(0),
  freeMonth(1),
  basic(2),
  plus(3),
  family(4),
  connect(5),
  creator(6),
  ambassador(7),
  artist(8),
  professional(9),
  premium(10),
  publish(11),
  platinum(12);

  final int value;
  const SubscriptionLevel(this.value);

}
