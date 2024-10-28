import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/subscription_plan.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/subscription_level.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class SubscriptionPlanFirestore {
  
  final subscriptionPlanReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.subscriptionPlans);

  @override
  Future<Map<String, SubscriptionPlan>> getAll() async {
    AppUtilities.logger.d("Retrieving Plans");
    Map<String, SubscriptionPlan> plans = {};

    try {

      QuerySnapshot querySnapshot = await subscriptionPlanReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("Snapshot is not empty");
        for (var planSnapshot in querySnapshot.docs) {
          SubscriptionPlan plan= SubscriptionPlan.fromJSON(planSnapshot.data());
          AppUtilities.logger.d(plan.toString());
          plans[planSnapshot.id] = plan;
        }
        AppUtilities.logger.d("${plans.length} plans found");

        // Ordenar los planes basados en el nivel
        final sortedPlans = Map.fromEntries(plans.entries.toList()
          ..sort((a, b) {
            // Obtener los niveles desde los nombres
            SubscriptionLevel levelA = a.value.level!;
            SubscriptionLevel levelB = b.value.level!;
            // Comparar por el valor numérico del nivel
            return levelA.value.compareTo(levelB.value);
          }));

        return sortedPlans;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return plans;
  }

  @override
  Future<List<SubscriptionPlan>> getPlansByType({required SubscriptionLevel level}) async {
    AppUtilities.logger.d("Retrieving Products by type ${level.name}");
    List<SubscriptionPlan> plans = [];

    try {

      QuerySnapshot querySnapshot = await subscriptionPlanReference
          .where(AppFirestoreConstants.level, isEqualTo: level.value)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.d("Snapshot is not empty");
        for (var planSnapshot in querySnapshot.docs) {
          SubscriptionPlan plan= SubscriptionPlan.fromJSON(planSnapshot.data());
          AppUtilities.logger.d(plan.toString());
          plans.add(plan);
        }
        AppUtilities.logger.d("${plans.length} plans found");
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return plans;
  }


  @override
  Future<String> insert(SubscriptionPlan plan) async {
    AppUtilities.logger.d("Inserting product ${plan.level?.name}");
    String planId = "";

    try {

      if(plan.id.isNotEmpty) {
        await subscriptionPlanReference.doc(plan.id).set(plan.toJSON());
        planId = plan.id;
      } else {
        DocumentReference documentReference = await subscriptionPlanReference
            .add(plan.toJSON());
        planId = documentReference.id;
        plan.id = planId;
        
      }
      AppUtilities.logger.d("SubscriptionPlan ${plan.level?.name} added with id ${plan.id}");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return planId;

  }


  @override
  Future<bool> remove(String planId) async {
    AppUtilities.logger.d("Removing product $planId");

    try {
      await subscriptionPlanReference.doc(planId).delete();
      AppUtilities.logger.d("Product $planId removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());      
    }
    return false;
  }


}
