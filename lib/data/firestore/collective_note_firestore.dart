import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_note.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

/// Firestore data access for [CollectiveNote] documents.
///
/// Notes are stored as a subcollection under each collective:
/// `collectives/{collectiveId}/notes/{noteId}`
class CollectiveNoteFirestore {

  var logger = AppConfig.logger;

  CollectionReference _notesRef(String collectiveId) =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.collectives)
          .doc(collectiveId)
          .collection(AppFirestoreCollectionConstants.collectiveNotes);

  /// Retrieves all notes for a collective, ordered by updatedAt descending.
  Future<List<CollectiveNote>> getNotes(String collectiveId) async {
    final cleanCollectiveId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return [];
    logger.t("Getting notes for collective $cleanCollectiveId");
    final notes = <CollectiveNote>[];

    try {
      final snapshot = await _notesRef(cleanCollectiveId)
          .orderBy('updatedAt', descending: true)
          .limit(200)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final note = CollectiveNote.fromJSON(data as Map<String, dynamic>);
        note.id = doc.id;
        notes.add(note);
      }
      logger.d("${notes.length} notes found for collective $cleanCollectiveId");
    } catch (e) {
      logger.e("getNotes error: $e");
    }

    return notes;
  }

  /// Retrieves a single note by ID.
  Future<CollectiveNote?> getNote(String collectiveId, String noteId) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanNoteId = noteId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanNoteId)) {
      return null;
    }
    logger.t("Getting note $cleanNoteId for collective $cleanCollectiveId");
    try {
      final doc = await _notesRef(cleanCollectiveId).doc(cleanNoteId).get();
      final data = doc.data();
      if (data == null) return null;
      final note = CollectiveNote.fromJSON(data as Map<String, dynamic>);
      note.id = doc.id;
      return note;
    } catch (e) {
      logger.e("getNote error: $e");
      return null;
    }
  }

  /// Inserts a new note. Returns the generated document ID.
  Future<String> insert(CollectiveNote note) async {
    final cleanCollectiveId = note.collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return '';
    logger.d("Inserting note '${note.title}' for collective $cleanCollectiveId");
    try {
      final doc = await _notesRef(cleanCollectiveId).add(note.toJSON());
      return doc.id;
    } catch (e) {
      logger.e("insert note error: $e");
      return '';
    }
  }

  /// Updates an existing note's content.
  Future<bool> update(CollectiveNote note) async {
    final cleanCollectiveId = note.collectiveId.trim();
    final cleanNoteId = note.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanNoteId)) {
      return false;
    }
    logger.d("Updating note '${note.title}' for collective $cleanCollectiveId");
    try {
      await _notesRef(cleanCollectiveId).doc(cleanNoteId).update(note.toJSON());
      return true;
    } catch (e) {
      logger.e("update note error: $e");
      return false;
    }
  }

  /// Deletes a note by ID.
  Future<bool> delete(String collectiveId, String noteId) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanNoteId = noteId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanNoteId)) {
      return false;
    }
    try {
      await _notesRef(cleanCollectiveId).doc(cleanNoteId).delete();
      return true;
    } catch (e) {
      logger.e("delete note error: $e");
      return false;
    }
  }
}
