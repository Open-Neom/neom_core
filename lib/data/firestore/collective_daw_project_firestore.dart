import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseFirestore? _injectedFirestore;
  final String? Function()? _authUidProvider;

  CollectiveDawProjectFirestore({
    FirebaseFirestore? firestore,
    String? Function()? authUidProvider,
  })  : _injectedFirestore = firestore,
        _authUidProvider = authUidProvider;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _firestore.collection(AppFirestoreCollectionConstants.dawProjects);

  String? _currentAuthUid() {
    final custom = _authUidProvider;
    if (custom != null) return custom();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return null;
      return user.uid;
    } catch (_) {
      return null;
    }
  }

  Future<List<CollectiveDawProject>> getByCollective(String collectiveId) async {
    final cleanCollectiveId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return [];
    final uid = _currentAuthUid();
    if (uid == null || uid.isEmpty) return [];

    final Map<String, CollectiveDawProject> merged = {};
    try {
      final results = await Future.wait([
        _projectsRef
            .where('ownerAuthUid', isEqualTo: uid)
            .where('collectiveId', isEqualTo: cleanCollectiveId)
            .limit(100)
            .get(),
        _projectsRef
            .where('collaboratorAuthUids', arrayContains: uid)
            .where('collectiveId', isEqualTo: cleanCollectiveId)
            .limit(100)
            .get(),
      ]);

      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          final project = CollectiveDawProject.fromJSON(doc.data());
          project.id = doc.id;
          merged[project.id] = project;
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'CollectiveDawProjectFirestore.getByCollective',
      );
    }
    final projects = merged.values.toList()
      ..sort((a, b) => b.updatedTime.compareTo(a.updatedTime));
    return projects;
  }

  Future<String> insert(CollectiveDawProject project) async {
    AppConfig.logger.d('Inserting CollectiveDawProject ${project.name}');
    try {
      if (project.ownerAuthUid.trim().isEmpty) {
        final uid = _currentAuthUid();
        if (uid == null || uid.isEmpty) return '';
        project.ownerAuthUid = uid;
      }
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
      return project.id;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'CollectiveDawProjectFirestore.insert',
      );
      return '';
    }
  }
}
