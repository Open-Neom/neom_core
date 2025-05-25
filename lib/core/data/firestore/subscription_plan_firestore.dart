import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_flavour.dart';
import '../../domain/model/subscription_plan.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/subscription_level.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class SubscriptionPlanFirestore {
  
  final subscriptionPlanReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.subscriptionPlans);

  Future<Map<String, SubscriptionPlan>> getAll() async {
    AppUtilities.logger.d("Retrieving Plans");
    Map<String, SubscriptionPlan> plans = {};

    try {

      QuerySnapshot querySnapshot = await subscriptionPlanReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.t("Snapshot is not empty");
        for (var planSnapshot in querySnapshot.docs) {
          SubscriptionPlan plan = SubscriptionPlan.fromJSON(planSnapshot.data());
          AppUtilities.logger.t(plan.toString());
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

  void insertSubscriptionPlans() async {
    SubscriptionPlanFirestore subscriptionPlanFirestore = SubscriptionPlanFirestore();
    List<SubscriptionPlan> subscriptionPlans = [];

    if(AppFlavour.appInUse == AppInUse.e) {
      // Lista de planes de suscripción con sus datos hardcodeados desde la imagen
      subscriptionPlans = [
        SubscriptionPlan(
          id: "artist",
          name: "artistPlan",
          productId: "prod_QzVWA5ZJaxrk6D",
          priceId: "price_1Q7WVWHpVUHkmiYFhVeMVKfC",
          level: SubscriptionLevel.artist,
          imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2023/12/Plan-de-suscripcion-Inicial.jpeg",
          href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-artista/",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "basic",
          name: "basicPlan",
          productId: "prod_QvY34BvmkRiWa",
          priceId: "price_1Q8STHpVUHkmiYF4l8sTLxO",
          level: SubscriptionLevel.basic,
          imgUrl: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-basico/",
          href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-basico/",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "creator",
          name: "creatorPlan",
          productId: "prod_ROV2TQ55pxymGI",
          priceId: "price_1Q8U2SHpVUHkmiYFRBSJk6xc",
          level: SubscriptionLevel.creator,
          imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2024/09/Plan-Posicionate.jpg",
          href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-posicionate/",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "premium",
          name: "premiumPlan",
          productId: "prod_Qzh8z4x5Nc9gd",
          priceId: "price_1Q7hkZHpVUHkmiYF6eDYloG",
          level: SubscriptionLevel.premium,
          imgUrl: 'https://www.escritoresmxi.org/wp-content/uploads/2023/12/Premium-cuadrado-imagen3.jpg',
          href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-premium/",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "professional",
          name: "professionalPlan",
          productId: "prod_QzVc88mKouprWR",
          priceId: "price_1Q7WbJHpVUHkmiYFEzTYW8XH",
          level: SubscriptionLevel.professional,
          imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2023/12/Plan-de-suscripcion-Profesional.jpeg",
          href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-profesional/",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "publish",
          name: "publishPlan",
          productId: "prod_ROUjpm5bHLoWY",
          priceId: "price_1Q8TjKHpVUHkmiYFfDmz1GBw",
          level: SubscriptionLevel.publish,
          imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2024/09/Plan-Publicate.jpg",
          href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-publicate/",
          isActive: true,
        ),
      ];
    } else {
      // Lista de planes de suscripción con sus datos hardcodeados desde la imagen
      subscriptionPlans = [
        SubscriptionPlan(
          id: "artist",
          name: "artistPlan",
          productId: "prod_RFSuVkICEfsxnT",
          priceId: "price_1QMxyMHS68rZKCuqipBeZONe",
          level: SubscriptionLevel.artist,
          imgUrl: "https://gigmeout.io/wp-content/uploads/2024/11/appIcon.png",
          href: "",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "basic",
          name: "basicPlan",
          productId: "prod_RFSuVkICEfsxnT",
          priceId: "price_1QMxCZHS68rZKCuq5vaxlLXv",
          level: SubscriptionLevel.basic,
          imgUrl: "https://gigmeout.io/wp-content/uploads/2024/11/appIcon.png",
          href: "",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "creator",
          name: "creatorPlan",
          productId: "prod_RFnEtMpLMLI4oU",
          priceId: "price_1QNHdwHS68rZKCuqaCaTJXNA",
          level: SubscriptionLevel.creator,
          imgUrl: "https://gigmeout.io/wp-content/uploads/2024/11/appIcon.png",
          href: "",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "premium",
          name: "premiumPlan",
          productId: "prod_RFT6pOpdGD90r6",
          priceId: "price_1QMyARHS68rZKCuq5KzaEiIh",
          level: SubscriptionLevel.premium,
          imgUrl: 'https://gigmeout.io/wp-content/uploads/2024/11/appIcon.png',
          href: "",
          isActive: true,
        ),
        SubscriptionPlan(
          id: "professional",
          name: "professionalPlan",
          productId: "prod_RFSztUaVtxzF1w",
          priceId: "price_1QMy36HS68rZKCuqIiY40u5S",
          level: SubscriptionLevel.professional,
          imgUrl: "https://gigmeout.io/wp-content/uploads/2024/11/appIcon.png",
          href: "",
          isActive: true,
        ),
      ];
    }

    // Inserta cada uno de los planes
    for (var plan in subscriptionPlans) {
      await subscriptionPlanFirestore.insert(plan);
      AppUtilities.logger.i("Inserted plan with ID: ${plan.id}");
    }
  }

}
