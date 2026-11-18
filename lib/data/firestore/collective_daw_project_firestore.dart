import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_daw_project.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

/// Minimal Firestore CRUD for [CollectiveDawProject] — covers the operations
/// needed by `neom_collectives` (list a collective's projects, create a new draft).
///
/// Reads and writes to the same `dawProjects` collection used by the full
/// `DawProjectFirestore` in `neom_daw`. Documents created here are
/// upgraded transparently the first time they are opened in the DAW
/// editor (which fills in tracks, buses, tempo map, etc).
class CollectiveDawProjectFirestore {
  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.dawProjects);

  Future<List<CollectiveDawProject>> getByCollective(String collectiveId) async {
    final cleanCollectiveId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return [];
    final List<CollectiveDawProject> projects = [];
    try {
      final query = await _projectsRef
          .where('collectiveId', isEqualTo: cleanCollectiveId)
          .orderBy('updatedTime', descending: true)
          .limit(200)
          .get();

      for (final doc in query.docs) {
        final project = CollectiveDawProject.fromJSON(doc.data());
        project.id = doc.id;
        projects.add(project);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'CollectiveDawProjectFirestore.getByCollective',
      );
    }
    return projects;
  }

  Future<String> insert(CollectiveDawProject project) async {
    AppConfig.logger.d('Inserting CollectiveDawProject ${project.name}');
    try {
      final cleanId = project.id.trim();
      if (cleanId.isNotEmpty) {
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
        await _projectsRef.doc(cleanId).set(project.toJSON());
      } else {
        final docRef = _projectsRef.doc();
        project.id = docRef.id;
        await docRef.set(project.toJSON());
      }
      AppConfig.logger.d(
        'CollectiveDawProject ${project.name} added with id ${project.id}',
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'CollectiveDawProjectFirestore.insert',
      );
    }
    return project.id;
  }
}
