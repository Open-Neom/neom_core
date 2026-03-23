enum AppMediaType {
  text('pdf'),
  image('jpg'),
  imageSlider('jpg'),
  eventImage('jpg'),
  video('mp4'),
  gif('gif'),
  youtube('mp4'),
  audio('mp3'),
  sharedPost('post');

  final String value;
  const AppMediaType(this.value);
}
