enum MediaItemType {
  audiobook('audiobook'),
  binaural('binaural'),
  book('book'),
  frequency('meditative'),
  nature('nature'),
  neomPreset('neomPreset'),
  pdf('pdf'),
  podcast('podcast'),
  song('song'),
  video('video');

  final String value;
  const MediaItemType(this.value);

  /// Returns true if this type represents playable audio content.
  bool get isAudio =>
      this == MediaItemType.song ||
      this == MediaItemType.podcast ||
      this == MediaItemType.audiobook ||
      this == MediaItemType.binaural ||
      this == MediaItemType.frequency ||
      this == MediaItemType.nature ||
      this == MediaItemType.neomPreset;

}
