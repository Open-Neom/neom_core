enum VerificationLevel {
  none(0),
  artist(1),
  professional(2),
  premium(3);
  //TODO TO add platinum(4);

  final int value;
  const VerificationLevel(this.value);

}
