/// A poll/vote within a collective.
///
/// Stored as subcollection `collectives/{id}/polls/{pollId}`
/// or embedded in chat messages.
class CollectivePoll {

  String id;
  String collectiveId;
  String question;
  List<PollOption> options;
  String createdBy;
  String creatorName;
  int createdAt;
  int expiresAt;       // 0 = no expiry
  bool isAnonymous;
  bool isMultiChoice;
  bool isClosed;

  CollectivePoll({
    this.id = '',
    this.collectiveId = '',
    this.question = '',
    this.options = const [],
    this.createdBy = '',
    this.creatorName = '',
    this.createdAt = 0,
    this.expiresAt = 0,
    this.isAnonymous = false,
    this.isMultiChoice = false,
    this.isClosed = false,
  });

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voterIds.length);

  Map<String, dynamic> toJSON() => {
    'collectiveId': collectiveId,
    'question': question,
    'options': options.map((o) => o.toJSON()).toList(),
    'createdBy': createdBy,
    'creatorName': creatorName,
    'createdAt': createdAt,
    'expiresAt': expiresAt,
    'isAnonymous': isAnonymous,
    'isMultiChoice': isMultiChoice,
    'isClosed': isClosed,
  };

  factory CollectivePoll.fromJSON(Map<String, dynamic> data) => CollectivePoll(
    id: data['id'] ?? '',
    collectiveId: data['collectiveId'] ?? '',
    question: data['question'] ?? '',
    options: (data['options'] as List<dynamic>?)
        ?.map((o) => PollOption.fromJSON(o as Map<String, dynamic>))
        .toList() ?? [],
    createdBy: data['createdBy'] ?? '',
    creatorName: data['creatorName'] ?? '',
    createdAt: data['createdAt'] ?? 0,
    expiresAt: data['expiresAt'] ?? 0,
    isAnonymous: data['isAnonymous'] ?? false,
    isMultiChoice: data['isMultiChoice'] ?? false,
    isClosed: data['isClosed'] ?? false,
  );

  @override
  String toString() => 'CollectivePoll{id: $id, question: $question, collectiveId: $collectiveId, totalVotes: $totalVotes}';
}

/// A single option within a [CollectivePoll].
class PollOption {

  String id;
  String text;
  List<String> voterIds;

  PollOption({
    this.id = '',
    this.text = '',
    this.voterIds = const [],
  });

  int get voteCount => voterIds.length;

  Map<String, dynamic> toJSON() => {
    'id': id,
    'text': text,
    'voterIds': voterIds,
  };

  factory PollOption.fromJSON(Map<String, dynamic> data) => PollOption(
    id: data['id'] ?? '',
    text: data['text'] ?? '',
    voterIds: List<String>.from(data['voterIds'] ?? []),
  );

  @override
  String toString() => 'PollOption{id: $id, text: $text, voteCount: $voteCount}';
}
