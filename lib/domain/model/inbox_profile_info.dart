
class InboxProfileInfo {

  final String profileId;
  final int lastTyping;/// Último momento en que escribió algo - milisecondsSinceEpoch
  final int lastReadAt;/// Futuro: último mensaje leído - milisecondsSinceEpoch
  final bool isMuted;/// Futuro: si silenció el chat
  final bool isBlocked;/// Futuro: si está bloqueado
  final Map<String, dynamic>? metadata;/// Futuro: metadata libre

  InboxProfileInfo({
    required this.profileId,
    this.lastTyping = 0,
    this.lastReadAt = 0,
    this.isMuted = false,
    this.isBlocked = false,
    this.metadata,
  });

  @override
  String toString() {
    return 'InboxProfileInfo{profileId: $profileId, lastTyping: $lastTyping, lastReadAt: $lastReadAt, isMuted: $isMuted, isBlocked: $isBlocked, metadata: $metadata}';
  }

  factory InboxProfileInfo.fromJSON(Map<String, dynamic> json) {
    return InboxProfileInfo(
      profileId: json['profileId'] ?? '',
      lastTyping: json['lastTyping'] ?? 0,
      lastReadAt: json['lastReadAt'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'profileId': profileId,
      'lastTyping': lastTyping,
      'lastReadAt': lastReadAt,
      'isMuted': isMuted,
      'isBlocked': isBlocked,
      'metadata': metadata,
    };
  }

}
