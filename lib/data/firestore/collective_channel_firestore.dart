import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_channel.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

/// Firestore data access for [CollectiveChannel] documents.
///
/// Channels are stored as a subcollection under each collective:
/// `collectives/{collectiveId}/channels/{channelId}`
class CollectiveChannelFirestore {

  var logger = AppConfig.logger;

  CollectionReference _channelsRef(String collectiveId) =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.collectives)
          .doc(collectiveId)
          .collection(AppFirestoreCollectionConstants.collectiveChannels);

  /// Retrieves all channels for a collective, ordered by [order].
  Future<List<CollectiveChannel>> getChannels(String collectiveId) async {
    final cleanCollectiveId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return [];
    logger.t("Getting channels for collective $cleanCollectiveId");
    final channels = <CollectiveChannel>[];

    try {
      final snapshot = await _channelsRef(cleanCollectiveId)
          .orderBy('order')
          .limit(100)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final channel = CollectiveChannel.fromJSON(data as Map<String, dynamic>);
        channel.id = doc.id;
        channels.add(channel);
      }
      logger.d("${channels.length} channels found for collective $cleanCollectiveId");
    } catch (e) {
      logger.e("getChannels error: $e");
    }

    return channels;
  }

  /// Inserts a new channel. Returns the generated document ID.
  Future<String> insert(CollectiveChannel channel) async {
    final cleanCollectiveId = channel.collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return '';
    logger.d("Inserting channel '${channel.name}' for collective $cleanCollectiveId");
    try {
      final doc = await _channelsRef(cleanCollectiveId).add(channel.toJSON());
      return doc.id;
    } catch (e) {
      logger.e("insert channel error: $e");
      return '';
    }
  }

  /// Creates default channels for a newly created collective.
  Future<void> createDefaults(String collectiveId) async {
    final cleanCollectiveId = collectiveId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId)) return;
    logger.d("Creating default channels for collective $cleanCollectiveId");
    try {
      final defaults = CollectiveChannel.defaults(cleanCollectiveId);
      for (final channel in defaults) {
        await insert(channel);
      }
    } catch (e) {
      logger.e("createDefaults error: $e");
    }
  }

  /// Deletes a channel by ID.
  Future<bool> delete(String collectiveId, String channelId) async {
    final cleanCollectiveId = collectiveId.trim();
    final cleanChannelId = channelId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCollectiveId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanChannelId)) {
      return false;
    }
    try {
      await _channelsRef(cleanCollectiveId).doc(cleanChannelId).delete();
      return true;
    } catch (e) {
      logger.e("delete channel error: $e");
      return false;
    }
  }
}
