enum VerificationLevel {
  none(0),
  verified(1),
  ambassador(2),
  artist(3),
  professional(4),
  premium(5),
  platinum(6);

  final int value;
  const VerificationLevel(this.value);

}
