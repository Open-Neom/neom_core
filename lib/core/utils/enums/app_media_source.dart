enum AppMediaSource {
  offline('offline'),
  internal('internal'),
  spotify('spotify'),
  youtube('youtube'),
  other('other');

  final String value;
  const AppMediaSource(this.value);

}

///Future Idea - Verify if is needed to add more sources
//   apple('apple'),
//   deezer('deezer'),
//   jiosaavn('jiosaavn'),
//   google('google'),
//   amazon('amazon'),
