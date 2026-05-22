import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/subscription_plan.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class SubscriptionPlanFirestore {
  
  final subscriptionPlanReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.subscriptionPlans);

  Future<Map<String, SubscriptionPlan>> getAll() async {
    AppConfig.logger.d("Retrieving Plans");
    Map<String, SubscriptionPlan> plans = {};

    try {

      QuerySnapshot querySnapshot = await subscriptionPlanReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.t("Snapshot is not empty");
        for (var planSnapshot in querySnapshot.docs) {
          SubscriptionPlan plan = SubscriptionPlan.fromJSON(planSnapshot.data());
          AppConfig.logger.t(plan.toString());
          plans[planSnapshot.id] = plan;
        }
        AppConfig.logger.d("${plans.length} plans found");

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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionPlanFirestore.getAll');
    }
    return plans;
  }

  Future<List<SubscriptionPlan>> getPlansByType({required SubscriptionLevel level}) async {
    AppConfig.logger.d("Retrieving Products by type ${level.name}");
    List<SubscriptionPlan> plans = [];

    try {

      QuerySnapshot querySnapshot = await subscriptionPlanReference
          .where(AppFirestoreConstants.level, isEqualTo: level.value)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("Snapshot is not empty");
        for (var planSnapshot in querySnapshot.docs) {
          SubscriptionPlan plan= SubscriptionPlan.fromJSON(planSnapshot.data());
          AppConfig.logger.d(plan.toString());
          plans.add(plan);
        }
        AppConfig.logger.d("${plans.length} plans found");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionPlanFirestore.getPlansByType');
    }
    return plans;
  }

  Future<String> insert(SubscriptionPlan plan) async {
    AppConfig.logger.d("Inserting product ${plan.level?.name}");
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
      AppConfig.logger.d("SubscriptionPlan ${plan.level?.name} added with id ${plan.id}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionPlanFirestore.insert');
    }

    return planId;

  }

  Future<bool> remove(String planId) async {
    AppConfig.logger.d("Removing product $planId");

    try {
      await subscriptionPlanReference.doc(planId).delete();
      AppConfig.logger.d("Product $planId removed");
      return true;

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionPlanFirestore.remove');
    }
    return false;
  }

  /// Updates a single field or multiple fields on an existing plan document.
  Future<void> update(String planId, Map<String, dynamic> data) async {
    try {
      await subscriptionPlanReference.doc(planId).update(data);
      AppConfig.logger.d("Plan $planId updated");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionPlanFirestore.update');
    }
  }

  /// Backfill isLive field on plans that don't have it yet.
  Future<int> backfillIsLive({bool defaultValue = true}) async {
    int updated = 0;
    try {
      final snapshot = await subscriptionPlanReference.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('isLive')) {
          await subscriptionPlanReference.doc(doc.id).update({'isLive': defaultValue});
          updated++;
        }
      }
      AppConfig.logger.d("backfillIsLive: $updated plans updated");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'SubscriptionPlanFirestore.backfillIsLive');
    }
    return updated;
  }

}
