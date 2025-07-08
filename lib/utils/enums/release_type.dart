enum ReleaseType {
  single("single"), ///BOOK | SONG | ARTICLE
  ep("ep"), ///G
  album("album"), ///G
  demo("demo"), ///G
  episode("episode"), ///PODCAST
  chapter("chapter"); ///AUDIOBOOK

  final String value;
  const ReleaseType(this.value);

}
