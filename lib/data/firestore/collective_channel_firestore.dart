import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/collective_channel.dart';
import 'constants/app_firestore_collection_constants.dart';

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
    logger.t("Getting channels for collective $collectiveId");
    final channels = <CollectiveChannel>[];

    try {
      final snapshot = await _channelsRef(collectiveId)
          .orderBy('order')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final channel = CollectiveChannel.fromJSON(data as Map<String, dynamic>);
        channel.id = doc.id;
        channels.add(channel);
      }
      logger.d("${channels.length} channels found for collective $collectiveId");
    } catch (e) {
      logger.e("getChannels error: $e");
    }

    return channels;
  }

  /// Inserts a new channel. Returns the generated document ID.
  Future<String> insert(CollectiveChannel channel) async {
    logger.d("Inserting channel '${channel.name}' for collective ${channel.collectiveId}");
    try {
      final doc = await _channelsRef(channel.collectiveId).add(channel.toJSON());
      return doc.id;
    } catch (e) {
      logger.e("insert channel error: $e");
      return '';
    }
  }

  /// Creates default channels for a newly created collective.
  Future<void> createDefaults(String collectiveId) async {
    logger.d("Creating default channels for collective $collectiveId");
    try {
      final defaults = CollectiveChannel.defaults(collectiveId);
      for (final channel in defaults) {
        await insert(channel);
      }
    } catch (e) {
      logger.e("createDefaults error: $e");
    }
  }

  /// Deletes a channel by ID.
  Future<bool> delete(String collectiveId, String channelId) async {
    try {
      await _channelsRef(collectiveId).doc(channelId).delete();
      return true;
    } catch (e) {
      logger.e("delete channel error: $e");
      return false;
    }
  }
}
