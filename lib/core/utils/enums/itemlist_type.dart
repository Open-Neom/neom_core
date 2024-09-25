enum ItemlistType {
  playlist("playlist"),
  giglist("giglist"),
  readlist("readlist"),
  publication('publication'),
  single("single"),
  ep("ep"),
  album("album"),
  demo('demo'),
  audiobook("audiobook"),
  podcast("podcast"),
  radioStation("radioStation");

  final String value;
  const ItemlistType(this.value);

}
