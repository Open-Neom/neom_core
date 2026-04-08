import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/band_daw_project.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';

/// Minimal Firestore CRUD for [BandDawProject] — covers the operations
/// needed by `neom_bands` (list a band's projects, create a new draft).
///
/// Reads and writes to the same `dawProjects` collection used by the full
/// `DawProjectFirestore` in `neom_daw`. Documents created here are
/// upgraded transparently the first time they are opened in the DAW
/// editor (which fills in tracks, buses, tempo map, etc).
class BandDawProjectFirestore {
  final _projectsRef = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.dawProjects);

  Future<List<BandDawProject>> getByBand(String bandId) async {
    if (bandId.isEmpty) return [];
    final List<BandDawProject> projects = [];
    try {
      final query = await _projectsRef
          .where('bandId', isEqualTo: bandId)
          .orderBy('updatedTime', descending: true)
          .get();

      for (final doc in query.docs) {
        final project = BandDawProject.fromJSON(doc.data());
        project.id = doc.id;
        projects.add(project);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'BandDawProjectFirestore.getByBand',
      );
    }
    return projects;
  }

  Future<String> insert(BandDawProject project) async {
    AppConfig.logger.d('Inserting BandDawProject ${project.name}');
    try {
      if (project.id.isNotEmpty) {
        await _projectsRef.doc(project.id).set(project.toJSON());
      } else {
        final docRef = await _projectsRef.add(project.toJSON());
        project.id = docRef.id;
        await _projectsRef.doc(project.id).update({'id': project.id});
      }
      AppConfig.logger.d(
        'BandDawProject ${project.name} added with id ${project.id}',
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'BandDawProjectFirestore.insert',
      );
    }
    return project.id;
  }
}
