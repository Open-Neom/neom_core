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
  meditation,
  gallery;

  bool get isAudio =>
      this == ItemlistType.playlist ||
      this == ItemlistType.giglist ||
      this == ItemlistType.single ||
      this == ItemlistType.ep ||
      this == ItemlistType.album ||
      this == ItemlistType.demo ||
      this == ItemlistType.audiobook ||
      this == ItemlistType.podcast ||
      this == ItemlistType.radioStation ||
      this == ItemlistType.meditation;

  /// Streamable audio lists shown in Gig Music / audio player feeds.
  ///
  /// Excludes [ItemlistType.giglist], which is strictly a musician repertoire
  /// list (YouTube Music references + preview-only for Songmate matching, not
  /// full-song streaming playlists).
  bool get isStreamableAudio => isAudio && this != ItemlistType.giglist;

  /// Whether this list represents a musician repertoire / connection list.
  bool get isRepertoire => this == ItemlistType.giglist;

}
