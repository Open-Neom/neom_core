/// A collaborative note/wiki page using Quill Delta format.
///
/// Stored as subcollection `collectives/{id}/notes/{noteId}`.
class CollectiveNote {

  String id;
  String collectiveId;
  String title;
  String contentJson;    // Quill Delta JSON string
  String plainText;      // plain text preview (first ~200 chars for listing)
  String createdBy;      // profile ID
  String lastEditedBy;   // profile ID
  String lastEditorName;
  int createdAt;
  int updatedAt;
  bool isPinned;
  String emoji;          // optional icon for the note

  CollectiveNote({
    this.id = '',
    this.collectiveId = '',
    this.title = '',
    this.contentJson = '',
    this.plainText = '',
    this.createdBy = '',
    this.lastEditedBy = '',
    this.lastEditorName = '',
    this.createdAt = 0,
    this.updatedAt = 0,
    this.isPinned = false,
    this.emoji = '',
  });

  Map<String, dynamic> toJSON() => {
    'collectiveId': collectiveId,
    'title': title,
    'contentJson': contentJson,
    'plainText': plainText,
    'createdBy': createdBy,
    'lastEditedBy': lastEditedBy,
    'lastEditorName': lastEditorName,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isPinned': isPinned,
    'emoji': emoji,
  };

  factory CollectiveNote.fromJSON(Map<String, dynamic> data) => CollectiveNote(
    id: data['id'] ?? '',
    collectiveId: data['collectiveId'] ?? '',
    title: data['title'] ?? '',
    contentJson: data['contentJson'] ?? '',
    plainText: data['plainText'] ?? '',
    createdBy: data['createdBy'] ?? '',
    lastEditedBy: data['lastEditedBy'] ?? '',
    lastEditorName: data['lastEditorName'] ?? '',
    createdAt: data['createdAt'] ?? 0,
    updatedAt: data['updatedAt'] ?? 0,
    isPinned: data['isPinned'] ?? false,
    emoji: data['emoji'] ?? '',
  );

  @override
  String toString() => 'CollectiveNote{id: $id, title: $title, collectiveId: $collectiveId, isPinned: $isPinned}';
}
