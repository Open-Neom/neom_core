import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_poll.dart';
import 'constants/app_firestore_collection_constants.dart';

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
    logger.t("Getting polls for collective $collectiveId");
    final polls = <CollectivePoll>[];

    try {
      final snapshot = await _pollsRef(collectiveId)
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final poll = CollectivePoll.fromJSON(data as Map<String, dynamic>);
        poll.id = doc.id;
        polls.add(poll);
      }
      logger.d("${polls.length} polls found for collective $collectiveId");
    } catch (e) {
      logger.e("getPolls error: $e");
    }

    return polls;
  }

  /// Inserts a new poll. Returns the generated document ID.
  Future<String> insert(CollectivePoll poll) async {
    logger.d("Inserting poll '${poll.question}' for collective ${poll.collectiveId}");
    try {
      final doc = await _pollsRef(poll.collectiveId).add(poll.toJSON());
      return doc.id;
    } catch (e) {
      logger.e("insert poll error: $e");
      return '';
    }
  }

  /// Adds a vote to a specific option within a poll.
  Future<bool> vote(String collectiveId, String pollId, String optionId, String voterId) async {
    logger.d("Voting on poll $pollId option $optionId for collective $collectiveId");
    try {
      final doc = await _pollsRef(collectiveId).doc(pollId).get();
      final data = doc.data();
      if (data == null) return false;

      final poll = CollectivePoll.fromJSON(data as Map<String, dynamic>);
      poll.id = doc.id;

      final updatedOptions = poll.options.map((option) {
        if (option.id == optionId && !option.voterIds.contains(voterId)) {
          return PollOption(
            id: option.id,
            text: option.text,
            voterIds: [...option.voterIds, voterId],
          );
        }
        return option;
      }).toList();

      await _pollsRef(collectiveId).doc(pollId).update({
        'options': updatedOptions.map((o) => o.toJSON()).toList(),
      });

      return true;
    } catch (e) {
      logger.e("vote error: $e");
      return false;
    }
  }

  /// Closes a poll so no more votes can be cast.
  Future<bool> close(String collectiveId, String pollId) async {
    logger.d("Closing poll $pollId for collective $collectiveId");
    try {
      await _pollsRef(collectiveId).doc(pollId).update({'isClosed': true});
      return true;
    } catch (e) {
      logger.e("close poll error: $e");
      return false;
    }
  }
}
