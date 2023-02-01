enum ProfileType {
  instrumentist("writer"),
  facilitator("facilitator"),
  host("host"),
  fan("reader"),
  band("collective");

  final String value;
  const ProfileType(this.value);
}
