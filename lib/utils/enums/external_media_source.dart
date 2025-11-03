enum ExternalSource {
  unknown('unknown'),
  spotify('spotify'),
  youtube('youtube'),
  google('google'),
  amazon('amazon'),
  apple('apple'),
  other('other');

  final String value;
  const ExternalSource(this.value);

}
