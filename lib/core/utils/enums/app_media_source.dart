enum AppMediaSource {
  offline('offline'),
  internal('internal'),
  youtube('youtube'),
  spotify('spotify'),
  apple('apple'),
  deezer('deezer'),
  jiosaavn('jiosaavn'),
  other('other');

  final String value;
  const AppMediaSource(this.value);

}
