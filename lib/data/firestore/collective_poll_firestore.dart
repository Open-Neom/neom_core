import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_poll.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

/// Firestore data access for [CollectivePoll] documents.
///
/// Polls are stored as a subcollection under each collective:
/// `collectives/{collectiveId}/polls/{pollId}`
class CollectivePollFirestore {

  var logger = AppConfig.logger;

  CollectionReference _pollsRef(String collectiveId) =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.collectives)
          .doc(collectiveId)
          .collection(AppFirestoreCollectionConstants.collectivePolls);

  /// Retrieves all polls for a collective, ordered by createdAt descending.
  Future<List<CollectivePoll>> getPolls(String collectiveId) async {
    final cleanCollectiveId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return [];
    logger.t("Getting polls for collective $cleanCollectiveId");
    final polls = <CollectivePoll>[];

    try {
      final snapshot = await _pollsRef(cleanCollectiveId)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final poll = CollectivePoll.fromJSON(data as Map<String, dynamic>);
        poll.id = doc.id;
        polls.add(poll);
      }
      logger.d("${polls.length} polls found for collective $cleanCollectiveId");
    } catch (e) {
      logger.e("getPolls error: $e");
    }

    return polls;
  }

  /// Inserts a new poll. Returns the generated document ID.
  Future<String> insert(CollectivePoll poll) async {
    final cleanCollectiveId = poll.collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return '';
    logger.d("Inserting poll '${poll.question}' for collective $cleanCollectiveId");
    try {
      final doc = await _pollsRef(cleanCollectiveId).add(poll.toJSON());
      return doc.id;
    } catch (e) {
      logger.e("insert poll error: $e");
      return '';
    }
  }

  /// Adds a vote to a specific option within a poll atomically.
  Future<bool> vote(String collectiveId, String pollId, String optionId, String voterId) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanPollId = pollId.trim();
    final cleanOptionId = optionId.trim();
    final cleanVoterId = voterId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanPollId) ||
        cleanOptionId.isEmpty ||
        !CoreFirestoreGuard.isSafeDocId(cleanVoterId)) {
      return false;
    }
    logger.d("Voting on poll $cleanPollId option $cleanOptionId for collective $cleanCollectiveId");
    try {
      final ref = _pollsRef(cleanCollectiveId).doc(cleanPollId);
      return await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final doc = await tx.get(ref);
        final data = doc.data();
        if (data is! Map) return false;
        final poll = CollectivePoll.fromJSON(Map<String, dynamic>.from(data));
        poll.id = doc.id;
        if (poll.isClosed) return false;

        final updatedOptions = poll.options.map((option) {
          if (option.id == cleanOptionId && !option.voterIds.contains(cleanVoterId)) {
            return PollOption(
              id: option.id,
              text: option.text,
              voterIds: [...option.voterIds, cleanVoterId],
            );
          }
          return option;
        }).toList();

        tx.update(ref, {
          'options': updatedOptions.map((o) => o.toJSON()).toList(),
        });
        return true;
      });
    } catch (e) {
      logger.e("vote error: $e");
      return false;
    }
  }

  /// Closes a poll so no more votes can be cast.
  Future<bool> close(String collectiveId, String pollId) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanPollId = pollId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanPollId)) {
      return false;
    }
    logger.d("Closing poll $cleanPollId for collective $cleanCollectiveId");
    try {
      await _pollsRef(cleanCollectiveId).doc(cleanPollId).update({'isClosed': true});
      return true;
    } catch (e) {
      logger.e("close poll error: $e");
      return false;
    }
  }
}
