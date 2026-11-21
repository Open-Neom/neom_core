
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app_config.dart';
import '../../domain/model/collective.dart';
import '../../domain/model/collective_member.dart';
import '../../domain/model/genre.dart';
import '../../domain/repository/collective_repository.dart';
import '../../utils/enums/collective_member_role.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';
import 'inbox_firestore.dart';
import 'itemlist_firestore.dart';
import 'profile_firestore.dart';
import 'request_firestore.dart';

class CollectiveFirestore implements CollectiveRepository {
  final FirebaseFirestore? _injectedFirestore;
  final String? Function()? _authUidProvider;

  CollectiveFirestore({
    FirebaseFirestore? firestore,
    String? Function()? authUidProvider,
  })  : _injectedFirestore = firestore,
        _authUidProvider = authUidProvider;

  var logger = AppConfig.logger;
  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get collectivesReference =>
      _firestore.collection(AppFirestoreCollectionConstants.collectives);

  String _currentAuthUid() {
    final custom = _authUidProvider;
    if (custom != null) return custom() ?? '';
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return '';
      return user.uid;
    } catch (_) {
      return '';
    }
  }

  static bool _isAdminRole(CollectiveMemberRole role) =>
      role == CollectiveMemberRole.founder ||
      role == CollectiveMemberRole.owner ||
      role == CollectiveMemberRole.lead ||
      role == CollectiveMemberRole.moderator;

  static List<String> _extractMemberProfileIds(Iterable<CollectiveMember> members) =>
      members
          .map((m) => m.profileId.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

  static List<String> _extractAdminProfileIds(Iterable<CollectiveMember> members) =>
      members
          .where((m) => m.profileId.trim().isNotEmpty && _isAdminRole(m.role))
          .map((m) => m.profileId.trim())
          .toSet()
          .toList();

  Future<void> _syncRosterMetadata(String collectiveId, {String? name, String? photoUrl}) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    try {
      final members = await getCollectiveMembers(cleanId);
      final memberIds = _extractMemberProfileIds(members.values);
      final adminIds = _extractAdminProfileIds(members.values);
      await collectivesReference.doc(cleanId).set(
        {
          'memberProfileIds': memberIds,
          'adminProfileIds': adminIds,
        },
        SetOptions(merge: true),
      );
      await InboxFirestore(firestore: _firestore).syncCollectiveRoomMembers(
        collectiveId: cleanId,
        profileIds: memberIds,
        adminIds: adminIds,
        name: name,
        photoUrl: photoUrl,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'CollectiveFirestore._syncRosterMetadata',
      );
    }
  }

  @override
  Future<Collective> retrieve(
    String collectiveId, {
    bool? onlyPublicItemlists,
    String? viewerProfileId,
  }) async {
    final cleanId = collectiveId.trim();
    Collective collective = Collective();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return collective;
    logger.t("Retrieving Collectives from firestore");

    try {
      DocumentSnapshot documentSnapshot = await collectivesReference.doc(cleanId).get();
      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        collective = Collective.fromJSON(documentSnapshot.data() as Map<String, dynamic>);
        collective.id = documentSnapshot.id;
        collective.members = await getCollectiveMembers(collective.id);
        final effectiveOnlyPublic = onlyPublicItemlists ??
            (!AppConfig.instance.canPersistUserActivity ||
                (viewerProfileId != null &&
                    viewerProfileId.trim().isNotEmpty &&
                    !collective.hasMemberProfile(viewerProfileId)));
        collective.itemlists = await ItemlistFirestore(firestore: _firestore).fetchAll(
          ownerId: collective.id,
          ownerType: OwnerType.collective,
          onlyPublic: effectiveOnlyPublic,
        );
        logger.t(collective.name);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.retrieve');
    }

    return collective;
  }


  Future<Collective?> getBySlug(String slug) async {
    final cleanSlug = slug.trim();
    if (cleanSlug.isEmpty) return null;
    try {
      final querySnapshot = await collectivesReference
          .where('slug', isEqualTo: cleanSlug)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final collective = Collective.fromJSON(doc.data());
        collective.id = doc.id;
        return collective;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.getBySlug');
    }
    return null;
  }

  /// Whether [name] is still free as a band name.
  ///
  /// Lets the create form reject a duplicate before submitting, instead of
  /// finding out after the user filled everything in.
  Future<bool> isNameAvailable(String name) async {
    if (name.trim().isEmpty) return false;
    return await getBySlug(Collective.generateSlug(name)) == null;
  }

  /// OPTIMIZED: Batch operations in parallel instead of sequential N+1
  @override
  Future<String> insert(Collective collective) async {
    logger.d("Inserting collective ${collective.name}");
    String collectiveId = "";
    try {
      if (collective.slug.isEmpty && collective.name.isNotEmpty) {
        collective.slug = Collective.generateSlug(collective.name);
      }

      if (collective.slug.isNotEmpty) {
        final existing = await getBySlug(collective.slug);
        if (existing != null) {
          logger.w("Collective name '${collective.name}' already taken by "
              "${existing.id}; refusing to create a duplicate");
          return '';
        }
      }

      collective.isActive = true;
      if (collective.createdTime == 0) {
        collective.createdTime = DateTime.now().millisecondsSinceEpoch;
      }
      if (collective.ownerAuthUid.isEmpty) {
        collective.ownerAuthUid = _currentAuthUid();
      }
      final memberValues = collective.members?.values ?? const <CollectiveMember>[];
      final memberIds = _extractMemberProfileIds(memberValues);
      final adminIds = _extractAdminProfileIds(memberValues);
      collective.memberProfileIds = memberIds;
      collective.adminProfileIds = adminIds;

      final docRef = collectivesReference.doc();
      collective.id = docRef.id;
      collectiveId = docRef.id;
      await docRef.set(collective.toJSON());

      final List<Future> operations = [];
      final Map<String, CollectiveMember> persistedMembers = {};

      if (collective.members != null) {
        for (var collectiveMember in collective.members!.values) {
          operations.add(
            _addMemberAndUpdateProfile(collectiveMember, collectiveId).then((memberDocId) {
              if (memberDocId.isNotEmpty) {
                collectiveMember.id = memberDocId;
                persistedMembers[memberDocId] = collectiveMember;
              }
            }),
          );
        }
      }

      if (collective.genres != null) {
        for (var genre in collective.genres!.values) {
          operations.add(addGenreToCollective(genre, collectiveId));
        }
      }

      operations.add(
        InboxFirestore(firestore: _firestore).ensureCollectiveRoom(
          collectiveId: collectiveId,
          name: collective.name,
          photoUrl: collective.photoUrl,
          description: collective.description,
          profileIds: memberIds,
          adminIds: adminIds,
        ),
      );

      await Future.wait(operations);
      if (persistedMembers.isNotEmpty) {
        collective.members = persistedMembers;
      }
      logger.i("Collective $collectiveId inserted with ${collective.members?.length ?? 0} members and ${collective.genres?.length ?? 0} genres");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.insert');
      return '';
    }

    return collectiveId;
  }

  /// Helper to add member and update profile in one operation
  Future<String> _addMemberAndUpdateProfile(CollectiveMember collectiveMember, String collectiveId) async {
    final docId = await _insertMemberDoc(collectiveMember, collectiveId);
    if (docId.isNotEmpty && collectiveMember.profileId.isNotEmpty) {
      if (_injectedFirestore == null) {
        await ProfileFirestore().addCollective(profileId: collectiveMember.profileId, collectiveId: collectiveId);
      }
    }
    return docId;
  }

  Future<String> _insertMemberDoc(CollectiveMember collectiveMember, String collectiveId) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
    try {
      final ref = collectivesReference
          .doc(cleanId)
          .collection(AppFirestoreCollectionConstants.members)
          .doc();
      collectiveMember.id = ref.id;
      final payload = collectiveMember.toJSON()..['id'] = ref.id;
      await ref.set(payload);
      return ref.id;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore._insertMemberDoc');
      return '';
    }
  }

  Future<bool> addMemberToCollective(CollectiveMember collectiveMember, String collectiveId) async {
    final docId = await _insertMemberDoc(collectiveMember, collectiveId);
    return docId.isNotEmpty;
  }

  @override
  Future<String> addCollectiveMember(String collectiveId, CollectiveMember collectiveMember) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
    final docId = await _addMemberAndUpdateProfile(collectiveMember, cleanId);
    if (docId.isNotEmpty) {
      await _syncRosterMetadata(cleanId);
    }
    return docId;
  }

  @override
  Future<bool> updateCollectiveMemberRole(
    String collectiveId,
    String memberId,
    CollectiveMemberRole role,
  ) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanMemberId = memberId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMemberId)) {
      return false;
    }
    try {
      await collectivesReference
          .doc(cleanCollectiveId)
          .collection(AppFirestoreCollectionConstants.members)
          .doc(cleanMemberId)
          .update({'role': role.name});
      await _syncRosterMetadata(cleanCollectiveId);
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'CollectiveFirestore.updateCollectiveMemberRole',
      );
      return false;
    }
  }

  /// OPTIMIZED: Parallel operations + removeCollectiveRequests called once (not N times)
  @override
  Future<bool> remove(Collective collective) async {
    final cleanId = collective.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    logger.d("Removing collective $cleanId");
    bool wasDeleted = false;
    try {
      final members = (collective.members != null && collective.members!.isNotEmpty)
          ? collective.members!
          : await getCollectiveMembers(cleanId);
      final genresSnap = await collectivesReference
          .doc(cleanId)
          .collection(AppFirestoreCollectionConstants.genres)
          .get();

      final List<Future> operations = [];

      // Delete member & genre subcollection docs
      for (final memberId in members.keys) {
        if (CoreFirestoreGuard.isSafeDocId(memberId)) {
          operations.add(
            collectivesReference
                .doc(cleanId)
                .collection(AppFirestoreCollectionConstants.members)
                .doc(memberId)
                .delete(),
          );
        }
      }
      for (final doc in genresSnap.docs) {
        operations.add(doc.reference.delete());
      }

      // Remove collective from every filled member's profile (keyed by doc id, NOT profileId)
      if (_injectedFirestore == null) {
        final seenProfileIds = <String>{};
        for (final member in members.values) {
          final pid = member.profileId.trim();
          if (pid.isNotEmpty && seenProfileIds.add(pid)) {
            operations.add(
              ProfileFirestore().removeCollective(profileId: pid, collectiveId: cleanId),
            );
          }
        }
        operations.add(RequestFirestore().removeCollectiveRequests(cleanId));
      }

      // Delete parent collective document and parent group inbox metadata doc
      operations.add(collectivesReference.doc(cleanId).delete());
      operations.add(
        InboxFirestore(firestore: _firestore)
            .inboxReference
            .doc(cleanId)
            .delete()
            .catchError((_) {}),
      );

      await Future.wait(operations);
      wasDeleted = true;
      logger.i("Collective $cleanId removed successfully");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.remove');
    }

    return wasDeleted;
  }


  /// OPTIMIZED: Added limit parameter to prevent full collection scan
  /// Also loads members in parallel instead of sequential N+1
  @override
  Future<Map<String, Collective>> getCollectives({int limit = 20}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 20, maxLimit: 200);
    logger.d("Getting collectives with limit: $safeLimit");
    Map<String, Collective> collectives = {};

    try {
      QuerySnapshot snapshot = await collectivesReference
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(safeLimit)
          .get();

      logger.d("${snapshot.docs.length} Collectives Found as Snapshot");

      final List<Collective> collectiveList = [];
      for (var documentSnapshot in snapshot.docs) {
        final data = documentSnapshot.data();
        if (data == null) continue;
        Collective collective = Collective.fromJSON(data as Map<String, dynamic>);
        collective.id = documentSnapshot.id;
        collectiveList.add(collective);
      }

      final memberFutures = collectiveList.map((b) => getCollectiveMembers(b.id));
      final memberResults = await Future.wait(memberFutures);

      for (int i = 0; i < collectiveList.length; i++) {
        collectiveList[i].members = memberResults[i];
        collectives[collectiveList[i].id] = collectiveList[i];
      }

      logger.d("${collectives.length} Collectives Found");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.getCollectives');
    }

    return collectives;
  }


  /// OPTIMIZED: Use whereIn instead of full collection scan + client filter
  @override
  Future<Map<String, Collective>> getCollectivesFromList(List<String> collectiveIds) async {
    logger.d("Retrieving ${collectiveIds.length} collectives from list");
    Map<String, Collective> collectives = {};

    final chunks = CoreFirestoreGuard.chunkValidIds(collectiveIds);
    if (chunks.isEmpty) return collectives;

    try {
      final List<Collective> collectiveList = [];

      for (final batch in chunks) {
        QuerySnapshot snapshot = await collectivesReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var documentSnapshot in snapshot.docs) {
          final data = documentSnapshot.data();
          if (data == null) continue;
          Collective collective = Collective.fromJSON(data as Map<String, dynamic>);
          collective.id = documentSnapshot.id;
          collectiveList.add(collective);
        }
      }

      if (collectiveList.isNotEmpty) {
        final memberFutures = collectiveList.map((b) => getCollectiveMembers(b.id));
        final memberResults = await Future.wait(memberFutures);

        for (int i = 0; i < collectiveList.length; i++) {
          collectiveList[i].members = memberResults[i];
          collectives[collectiveList[i].id] = collectiveList[i];
        }
      }

      logger.d("${collectives.length} Collectives Found");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.getCollectivesFromList');
    }

    return collectives;
  }



  @override
  Future<bool> fulfillCollectiveMember(String collectiveId, CollectiveMember collectiveMember) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanMemberId = collectiveMember.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMemberId)) {
      return false;
    }
    logger.d("Fulfilling collectiveMember ${collectiveMember.name} for collective $cleanCollectiveId");

    try {
      await collectivesReference
          .doc(cleanCollectiveId)
          .collection(AppFirestoreCollectionConstants.members)
          .doc(cleanMemberId)
          .update({
            AppFirestoreConstants.imgUrl: collectiveMember.imgUrl,
            AppFirestoreConstants.name: collectiveMember.name,
            AppFirestoreConstants.profileId: collectiveMember.profileId,
          });
      if (_injectedFirestore == null && collectiveMember.profileId.trim().isNotEmpty) {
        await ProfileFirestore().addCollective(
          profileId: collectiveMember.profileId,
          collectiveId: cleanCollectiveId,
        );
      }
      await _syncRosterMetadata(cleanCollectiveId);
      logger.i("CollectiveMember ${collectiveMember.name} has been fulfilled");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.fulfillCollectiveMember');
      return false;
    }

    return true;
  }


  @override
  Future<bool> unfulfillCollectiveMember(String collectiveId, CollectiveMember collectiveMember) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanMemberId = collectiveMember.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMemberId)) {
      return false;
    }
    logger.d("Unfulfilling collectiveMember ${collectiveMember.name} for collective $cleanCollectiveId");

    try {
      await collectivesReference
          .doc(cleanCollectiveId)
          .collection(AppFirestoreCollectionConstants.members)
          .doc(cleanMemberId)
          .update({
            AppFirestoreConstants.imgUrl: "",
            AppFirestoreConstants.name: "",
            AppFirestoreConstants.profileId: "",
          });
      if (_injectedFirestore == null && collectiveMember.profileId.trim().isNotEmpty) {
        await ProfileFirestore().removeCollective(
          profileId: collectiveMember.profileId,
          collectiveId: cleanCollectiveId,
        );
      }
      await _syncRosterMetadata(cleanCollectiveId);
      logger.i("CollectiveMember ${collectiveMember.name} has been unfulfilled");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.unfulfillCollectiveMember');
      return false;
    }

    return true;
  }

  @override
  Future<bool> removeCollectiveMember(String collectiveId, CollectiveMember collectiveMember) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanMemberId = collectiveMember.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanMemberId)) {
      return false;
    }
    logger.d("Removing collectiveMember ${collectiveMember.name} for collective $cleanCollectiveId");

    try {
      await collectivesReference
          .doc(cleanCollectiveId)
          .collection(AppFirestoreCollectionConstants.members)
          .doc(cleanMemberId)
          .delete();

      if (_injectedFirestore == null && collectiveMember.profileId.trim().isNotEmpty) {
        await ProfileFirestore().removeCollective(
          profileId: collectiveMember.profileId,
          collectiveId: cleanCollectiveId,
        );
      }
      await _syncRosterMetadata(cleanCollectiveId);
      logger.i("CollectiveMember ${collectiveMember.name} has been removed");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.removeCollectiveMember');
      return false;
    }

    return true;
  }

  @override
  Future<bool> isAvailableName(String collectiveName) =>
      isNameAvailable(collectiveName);


  Future<Map<String,CollectiveMember>> getCollectiveMembers(String collectiveId) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return {};
    logger.t("getCollectiveMembers on firestore");

    Map<String,CollectiveMember> collectiveMembers = {};

    try {
      QuerySnapshot querySnapshot = await collectivesReference.doc(cleanId)
          .collection(AppFirestoreCollectionConstants.members).get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var collectiveMemberSnapshot in querySnapshot.docs) {
          final data = collectiveMemberSnapshot.data();
          if (data == null) continue;
          CollectiveMember collectiveMember = CollectiveMember.fromJSON(data as Map<String, dynamic>);
          collectiveMember.id = collectiveMemberSnapshot.id;
          logger.t('Collective member ${collectiveMember.instrument?.name} - ${collectiveMember.name.isNotEmpty
              ? collectiveMember.name : 'unfulfilled'} - retrieved for collective $cleanId');

          collectiveMembers[collectiveMember.id] = collectiveMember;
        }
        logger.d("${collectiveMembers.length} members retrieved for collective $cleanId");
      } else {
        logger.d("No collective members found for collective $cleanId");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.getCollectiveMembers');
    }

    return collectiveMembers;
  }


  Future<Map<String,Genre>> getCollectiveGenres(String collectiveId) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return {};
    logger.t("Get genres for collective $cleanId");

    Map<String,Genre> collectiveGenres = {};

    try {
      QuerySnapshot querySnapshot = await collectivesReference.doc(cleanId)
          .collection(AppFirestoreCollectionConstants.genres)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        for (var collectiveMemberSnapshot in querySnapshot.docs) {
          Genre genre = Genre.fromQueryDocumentSnapshot(collectiveMemberSnapshot);
          logger.t(genre.name);

          collectiveGenres[genre.name] = genre;
        }
        logger.d("${collectiveGenres.length} genres retrieved");
      } else {
        logger.d("No collective genres found");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'CollectiveFirestore.getCollectiveGenres');
    }

    return collectiveGenres;
  }


  Future<bool> addGenreToCollective(Genre genre, String collectiveId) async {
    final cleanId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    logger.d("Adding genre to collective $cleanId");
    bool addedGenre = false;

    try {
      await collectivesReference
          .doc(cleanId)
          .collection(AppFirestoreCollectionConstants.genres)
          .add(genre.toJSON());

      addedGenre = true;
    } catch (e) {
      logger.e(e.toString());
    }
    addedGenre ? logger.d("Genre was added to collective $cleanId") :
    logger.d("Genre was not added to collective $cleanId");
    return addedGenre;
  }

  /// OPTIMIZED: Direct document access instead of scanning all collectives
  @override
  Future<bool> addPlayingEvent(String collectiveId, String eventId) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanEventId = eventId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanEventId)) {
      return false;
    }
    logger.t("$cleanCollectiveId would add event $cleanEventId");

    try {
      // OPTIMIZATION: Direct document update instead of full collection scan
      await collectivesReference.doc(cleanCollectiveId).update({
        AppFirestoreConstants.playingEvents: FieldValue.arrayUnion([cleanEventId])
      });

      logger.d("$cleanCollectiveId has added event $cleanEventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }

  /// OPTIMIZED: Direct document updates in parallel instead of scanning all collectives
  @override
  Future<bool> addPlayingEventToCollectives(List<String> collectiveIds, String eventId) async {
    final cleanEventId = eventId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanEventId)) return false;
    logger.d("$collectiveIds would add $cleanEventId");

    final validIds = collectiveIds
        .map((id) => id.trim())
        .where(CoreFirestoreGuard.isSafeDocId)
        .toList();
    if (validIds.isEmpty) return true;

    try {
      // OPTIMIZATION: Update each collective directly in parallel
      final updates = validIds.map((collectiveId) =>
        collectivesReference.doc(collectiveId).update({
          AppFirestoreConstants.playingEvents: FieldValue.arrayUnion([cleanEventId])
        })
      );

      await Future.wait(updates);

      logger.d("$validIds has added event $cleanEventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  /// OPTIMIZED: Direct document access instead of scanning all collectives
  @override
  Future<bool> removePlayingEvent(String collectiveId, String eventId) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanEventId = eventId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanEventId)) {
      return false;
    }
    logger.d("Collective $cleanCollectiveId would remove event $cleanEventId");

    try {
      // OPTIMIZATION: Direct document update instead of full collection scan
      await collectivesReference.doc(cleanCollectiveId).update({
        AppFirestoreConstants.playingEvents: FieldValue.arrayRemove([cleanEventId])
      });

      logger.d("$cleanCollectiveId has removed event $cleanEventId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }


  ///DEPRECATED
  // @override
  // Future<bool> addAppMediaItem(String collectiveId, String itemId) async {
  //   logger.d("");
  //   try {
  //
  //     await collectivesReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == collectiveId) {
  //           await document.reference.update({
  //             AppFirestoreConstants.appMediaItems: FieldValue.arrayUnion([itemId])
  //           });
  //         }
  //       }
  //     });
  //
  //   } catch (e) {
  //     logger.e(e.toString());
  //     return false;
  //   }
  //
  //   return true;
  // }
  //
  //
  // @override
  // Future<bool> removeItem(String collectiveId, String itemId) async {
  //   logger.d("");
  //   try {
  //
  //     await collectivesReference.get()
  //         .then((querySnapshot) async {
  //       for (var document in querySnapshot.docs) {
  //         if(document.id == collectiveId) {
  //           await document.reference.update({
  //             AppFirestoreConstants.appMediaItems: FieldValue.arrayRemove([itemId])
  //           });
  //         }
  //       }
  //     });
  //
  //   } catch (e) {
  //     logger.e(e.toString());
  //     return false;
  //   }
  //
  //   return true;
  // }

}
