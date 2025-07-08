enum AppItemState {
  noState(0),
  heardIt(1),
  learningIt(2),
  needToPractice(3),
  readyToPlay(4),
  knowByHeart(5);

  final int value;
  const AppItemState(this.value);
}
