enum AppMediaSource {
  offline('offline'),
  internal('internal'),
  external('external'),
  jamendo('jamendo'),
  publicDomain('publicDomain');

  final String value;
  const AppMediaSource(this.value);

}
