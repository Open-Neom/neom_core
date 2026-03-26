enum VerificationLevel {
  none(0),
  basic(1),
  verified(2),
  creator(3),
  ambassador(4),
  artist(5),
  professional(6),
  premium(7),
  platinum(8);

  final int value;
  const VerificationLevel(this.value);

}
