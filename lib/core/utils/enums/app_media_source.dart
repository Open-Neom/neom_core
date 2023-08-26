enum AppMediaSource {
  offline('offline'),
  internal('internal'),
  youtube('youtube'),
  spotify('spotify'),
  apple('apple'),
  jiosaavn('jiosaavn'),
  deezer('deezer'),
  other('other');

  final String value;
  const AppMediaSource(this.value);

}
