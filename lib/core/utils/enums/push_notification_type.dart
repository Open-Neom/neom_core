enum PushNotificationType {
  like(1),
  comment(2),
  request(3),
  message(4),
  eventCreated(5),
  goingEvent(6),
  viewProfile(7),
  following(8),
  post(9),
  blog(10),
  appItemAdded(11),
  releaseAppItemAdded(12),
  chamberPresetAdded(13);

  final int value;
  const PushNotificationType(this.value);
}
