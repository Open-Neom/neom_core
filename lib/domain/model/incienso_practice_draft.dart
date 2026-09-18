/// The only Incienso data a published reflection may carry. Never attach audio
/// parameters, a timeline, creator identifiers, or a private recording ID here.
class InciensoPracticeReference {
  final String inciensoName;
  final String publicInciensoId;

  const InciensoPracticeReference({
    required this.inciensoName,
    this.publicInciensoId = '',
  });

  bool get canOpen => publicInciensoId.isNotEmpty;

  Map<String, dynamic> toJSON() => {
    'inciensoName': inciensoName,
    if (canOpen) 'publicInciensoId': publicInciensoId,
  };

  factory InciensoPracticeReference.fromJSON(Map data) {
    return InciensoPracticeReference(
      inciensoName: data['inciensoName'] is String ? data['inciensoName'] : '',
      publicInciensoId: data['publicInciensoId'] is String
          ? data['publicInciensoId']
          : '',
    );
  }
}

/// Route argument for an editable, local-first neom_blog reflection.
/// Only pass a publicInciensoId when the source is a public or built-in session.
/// Opening this argument must never publish or upload a draft automatically.
class InciensoPracticeDraft {
  final String sessionId;
  final String inciensoName;
  final String publicInciensoId;
  final int durationSeconds;
  final String feelingBefore;
  final String feelingAfter;
  final String note;

  const InciensoPracticeDraft({
    required this.sessionId,
    required this.inciensoName,
    this.publicInciensoId = '',
    this.durationSeconds = 0,
    this.feelingBefore = '',
    this.feelingAfter = '',
    this.note = '',
  });

  InciensoPracticeReference get reference => InciensoPracticeReference(
    inciensoName: inciensoName,
    publicInciensoId: publicInciensoId,
  );
}
