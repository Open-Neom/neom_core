enum ItemlistType {
  playlist("playlist"),
  giglist("giglist"),
  readlist("readlist"),
  single("single"),
  ep("ep"),
  album("album"),
  demo('demo'),
  audiobook("audiobook"),
  podcast("podcast"),
  radioStation("radioStation"),
  chamberPresets("chamberPresets");

  final String value;
  const ItemlistType(this.value);

}
