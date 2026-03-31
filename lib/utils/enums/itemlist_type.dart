enum ItemlistType {
  playlist,
  giglist,
  readlist,
  publication,
  single,
  ep,
  album,
  demo,
  audiobook,
  podcast,
  radioStation,
  meditation;

  bool get isAudio =>
      this == ItemlistType.playlist ||
      this == ItemlistType.single ||
      this == ItemlistType.ep ||
      this == ItemlistType.album ||
      this == ItemlistType.demo ||
      this == ItemlistType.audiobook ||
      this == ItemlistType.podcast ||
      this == ItemlistType.radioStation ||
      this == ItemlistType.meditation;

}
