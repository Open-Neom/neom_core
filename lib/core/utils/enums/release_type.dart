enum ReleaseType {
  single("single"), 
  ep("ep"),
  album("album"),
  demo("demo"),
  episode("episode"), ///PODCAST
  chapter("chapter"); ///AUDIOBOOK

  final String value;
  const ReleaseType(this.value);

}
