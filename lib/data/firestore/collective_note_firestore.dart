import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_note.dart';
import 'constants/app_firestore_collection_constants.dart';

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
    logger.t("Getting notes for collective $collectiveId");
    final notes = <CollectiveNote>[];

    try {
      final snapshot = await _notesRef(collectiveId)
          .orderBy('updatedAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final note = CollectiveNote.fromJSON(data as Map<String, dynamic>);
        note.id = doc.id;
        notes.add(note);
      }
      logger.d("${notes.length} notes found for collective $collectiveId");
    } catch (e) {
      logger.e("getNotes error: $e");
    }

    return notes;
  }

  /// Retrieves a single note by ID.
  Future<CollectiveNote?> getNote(String collectiveId, String noteId) async {
    logger.t("Getting note $noteId for collective $collectiveId");
    try {
      final doc = await _notesRef(collectiveId).doc(noteId).get();
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
    logger.d("Inserting note '${note.title}' for collective ${note.collectiveId}");
    try {
      final doc = await _notesRef(note.collectiveId).add(note.toJSON());
      return doc.id;
    } catch (e) {
      logger.e("insert note error: $e");
      return '';
    }
  }

  /// Updates an existing note's content.
  Future<bool> update(CollectiveNote note) async {
    logger.d("Updating note '${note.title}' for collective ${note.collectiveId}");
    try {
      await _notesRef(note.collectiveId).doc(note.id).update(note.toJSON());
      return true;
    } catch (e) {
      logger.e("update note error: $e");
      return false;
    }
  }

  /// Deletes a note by ID.
  Future<bool> delete(String collectiveId, String noteId) async {
    try {
      await _notesRef(collectiveId).doc(noteId).delete();
      return true;
    } catch (e) {
      logger.e("delete note error: $e");
      return false;
    }
  }
}
