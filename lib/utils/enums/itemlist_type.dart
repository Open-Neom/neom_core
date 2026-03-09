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

  bool get isAudio =>
      this == ItemlistType.playlist ||
      this == ItemlistType.single ||
      this == ItemlistType.ep ||
      this == ItemlistType.album ||
      this == ItemlistType.demo ||
      this == ItemlistType.audiobook ||
      this == ItemlistType.podcast ||
      this == ItemlistType.radioStation;

}
