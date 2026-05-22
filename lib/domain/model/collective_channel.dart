/// A topic-based messaging channel within a Collective.
///
/// Provides Slack-like organization for collective communication.
/// Each collective has a default '#general' channel; owners/managers
/// can create additional channels for specific topics.
///
/// The roomId for inbox messaging is derived as:
/// `"${collectiveId}_${id}"` — this keeps channels separate in Firestore
/// while reusing the full neom_inbox infrastructure.
class CollectiveChannel {

  String id;
  String collectiveId;
  String name;
  String description;
  String emoji;
  bool isDefault;
  int order;
  int createdAt;

  CollectiveChannel({
    this.id = '',
    this.collectiveId = '',
    this.name = 'general',
    this.description = '',
    this.emoji = '\u{1F4AC}', // 💬
    this.isDefault = false,
    this.order = 0,
    this.createdAt = 0,
  });

  /// Derives the inbox room ID used for messaging in this channel.
  String get roomId => '${collectiveId}_$id';

  Map<String, dynamic> toJSON() => {
    'collectiveId': collectiveId,
    'name': name,
    'description': description,
    'emoji': emoji,
    'isDefault': isDefault,
    'order': order,
    'createdAt': createdAt,
  };

  factory CollectiveChannel.fromJSON(Map<String, dynamic> data) => CollectiveChannel(
    id: data['id'] ?? '',
    collectiveId: data['collectiveId'] ?? '',
    name: data['name'] ?? 'general',
    description: data['description'] ?? '',
    emoji: data['emoji'] ?? '\u{1F4AC}',
    isDefault: data['isDefault'] ?? false,
    order: data['order'] ?? 0,
    createdAt: data['createdAt'] ?? 0,
  );

  /// Creates default channels for a new collective.
  static List<CollectiveChannel> defaults(String collectiveId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      CollectiveChannel(
        collectiveId: collectiveId,
        name: 'general',
        emoji: '\u{1F4AC}', // 💬
        isDefault: true,
        order: 0,
        createdAt: now,
      ),
    ];
  }

  @override
  String toString() => 'CollectiveChannel{id: $id, name: $name, collectiveId: $collectiveId, isDefault: $isDefault}';
}
