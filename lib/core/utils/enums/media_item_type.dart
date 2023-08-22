enum MediaItemType {
  song('song'),
  video('video'),
  pdf('pdf'),
  podcast('podcast'),
  audiobook('audiobook'),
  neomPreset('neomPreset'),
  binaural('binaural'),
  frequency('meditative'),
  nature('nature');

  final String value;
  const MediaItemType(this.value);

}
