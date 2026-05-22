import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_daw_project.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';

/// Minimal Firestore CRUD for [CollectiveDawProject] — covers the operations
/// needed by `neom_collectives` (list a collective's projects, create a new draft).
///
/// Reads and writes to the same `dawProjects` collection used by the full
/// `DawProjectFirestore` in `neom_daw`. Documents created here are
/// upgraded transparently the first time they are opened in the DAW
/// editor (which fills in tracks, buses, tempo map, etc).
class CollectiveDawProjectFirestore {
  final _projectsRef = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.dawProjects);

  Future<List<CollectiveDawProject>> getByCollective(String collectiveId) async {
    if (collectiveId.isEmpty) return [];
    final List<CollectiveDawProject> projects = [];
    try {
      final query = await _projectsRef
          .where('collectiveId', isEqualTo: collectiveId)
          .orderBy('updatedTime', descending: true)
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
      if (project.id.isNotEmpty) {
        await _projectsRef.doc(project.id).set(project.toJSON());
      } else {
        final docRef = await _projectsRef.add(project.toJSON());
        project.id = docRef.id;
        await _projectsRef.doc(project.id).update({'id': project.id});
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
