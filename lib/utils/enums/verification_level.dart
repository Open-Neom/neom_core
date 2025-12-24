enum VerificationLevel {
  none(0),
  verified(1),
  creator(2),
  ambassador(3),
  artist(4),
  professional(5),
  premium(6),
  platinum(7);

  final int value;
  const VerificationLevel(this.value);

}
