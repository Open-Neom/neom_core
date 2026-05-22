import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_file.dart';
import 'constants/app_firestore_collection_constants.dart';

/// Firestore data access for [CollectiveFile] documents.
///
/// Files are stored as a subcollection under each collective:
/// `collectives/{collectiveId}/files/{fileId}`
class CollectiveFileFirestore {

  var logger = AppConfig.logger;

  CollectionReference _filesRef(String collectiveId) =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.collectives)
          .doc(collectiveId)
          .collection(AppFirestoreCollectionConstants.collectiveFiles);

  /// Retrieves all files for a collective, optionally filtered by [folder].
  Future<List<CollectiveFile>> getFiles(String collectiveId, {String? folder}) async {
    logger.t("Getting files for collective $collectiveId${folder != null ? ' in folder $folder' : ''}");
    final files = <CollectiveFile>[];

    try {
      Query query = _filesRef(collectiveId).orderBy('createdAt', descending: true);
      if (folder != null && folder.isNotEmpty) {
        query = query.where('folder', isEqualTo: folder);
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final file = CollectiveFile.fromJSON(data as Map<String, dynamic>);
        file.id = doc.id;
        files.add(file);
      }
      logger.d("${files.length} files found for collective $collectiveId");
    } catch (e) {
      logger.e("getFiles error: $e");
    }

    return files;
  }

  /// Inserts a new file. Returns the generated document ID.
  Future<String> insert(CollectiveFile file) async {
    logger.d("Inserting file '${file.name}' for collective ${file.collectiveId}");
    try {
      final doc = await _filesRef(file.collectiveId).add(file.toJSON());
      return doc.id;
    } catch (e) {
      logger.e("insert file error: $e");
      return '';
    }
  }

  /// Deletes a file by ID.
  Future<bool> delete(String collectiveId, String fileId) async {
    try {
      await _filesRef(collectiveId).doc(fileId).delete();
      return true;
    } catch (e) {
      logger.e("delete file error: $e");
      return false;
    }
  }
}
