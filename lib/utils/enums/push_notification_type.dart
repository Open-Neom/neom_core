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
  chamberPresetAdded(13),
  roomReaction(14),
  gameInvitation(15),
  gameInvitationAccepted(16),
  gameInvitationDeclined(17),
  tip(18),
  repost(19),
  achievementUnlocked(20),
  storyReaction(21),
  liveSessionStarted(22),
  communityMessage(23),
  scheduledPostPublished(24),
  royaltyDeposited(25),
  royaltiesClaimed(26),
  shopOrderUpdate(27),
  remoteCommandCompleted(28);

  final int value;
  const PushNotificationType(this.value);
}
