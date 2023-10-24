import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/sponsor.dart';
import '../../domain/repository/sponsor_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class SponsorFirestore implements SponsorRepository {

  var logger = AppUtilities.logger;
  final sponsorsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.sponsors);
  List<QueryDocumentSnapshot> _documentTimeline = [];
  int documentTimelineCounter = 0;

  @override
  Future<String> insert(Sponsor sponsor) async {
    logger.d("");
    String sponsorId = "";
    try {
      DocumentReference documentReference = await sponsorsReference
          .add(sponsor.toJSON());
      sponsorId = documentReference.id;

      logger.i("Sponsor Inserted with Id $sponsorId");
    } catch (e) {
      logger.e(e.toString());
    }

    return sponsorId;
  }

  @override
  Future<Map<String, Sponsor>> getSponsorsTimeline() async {
    logger.t("");
    Map<String, Sponsor> sponsors = {};

    try {
      QuerySnapshot snapshot = await sponsorsReference
          .limit(AppConstants.sponsorsLimit)
          .where(AppFirestoreConstants.isActive, isEqualTo: true)
          .get();

      _documentTimeline = snapshot.docs;

      for (int i = 0; i < _documentTimeline.length; i++) {
        Sponsor sponsor = Sponsor.fromJSON(_documentTimeline.elementAt(i).data());
        sponsor.id = _documentTimeline.elementAt(i).id;
        sponsors[sponsor.id] = sponsor;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    //documentTimelineCounter++;
    return sponsors;
  }

  @override
  Future<Map<String, Sponsor>> getNextSponsorsTimeline() async {
    logger.d("Getting Next Timeline Posts");
    Map<String, Sponsor> sponsors = {};

    try {
      QuerySnapshot snapshot = await sponsorsReference
          .startAfterDocument(_documentTimeline[documentTimelineCounter++])
          .limit(AppConstants.sponsorsLimit).get();

      _documentTimeline.addAll(snapshot.docs);

      for (int i = 0; i < snapshot.docs.length; i++) {
        Sponsor sponsor = Sponsor.fromJSON(snapshot.docs.elementAt(i).data());
        sponsor.id = snapshot.docs.elementAt(i).id;
        sponsors[sponsor.id] = sponsor;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return sponsors;
  }


}
