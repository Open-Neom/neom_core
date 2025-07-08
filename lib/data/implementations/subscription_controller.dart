import 'package:get/get.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/price.dart';
import '../../domain/model/stripe/stripe_price.dart';
import '../../domain/model/subscription_plan.dart';
import '../../domain/model/user_subscription.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import '../api_services/stripe/stripe_service.dart';
import '../firestore/profile_firestore.dart';
import '../firestore/subscription_plan_firestore.dart';
import '../firestore/user_subscription_firestore.dart';
import 'user_controller.dart';

class SubscriptionController extends GetxController with GetTickerProviderStateMixin {

  final userController = Get.find<UserController>();
  // AppProfileController appProfileController = Get.put(AppProfileController());
  AppProfile profile = AppProfile();

  RxBool isLoading = true.obs;
  // Rx<SubscriptionLevel> selectedLevel = SubscriptionLevel.basic.obs;
  Rx<String> selectedPlanName = ''.obs;
  Rx<String> selectedPlanImgUrl = ''.obs;
  Rx<Price> selectedPrice = Price().obs;
  SubscriptionPlan selectedPlan = SubscriptionPlan();
  Map<String, SubscriptionPlan> subscriptionPlans = {};
  RxMap<String, SubscriptionPlan> profilePlans = <String, SubscriptionPlan>{}.obs;
  RxMap<SubscriptionLevel,List<UserSubscription>> activeSubscriptions = <SubscriptionLevel,List<UserSubscription>>{}.obs;

  Rx<ProfileType>  profileType = ProfileType.general.obs;
  Rx<FacilityType>  facilityType = FacilityType.general.obs;
  Rx<PlaceType>  placeType = PlaceType.general.obs;


  @override
  void onInit() {
    super.onInit();
    // Map<String, List<StripePrice>> recurringPrices = await StripeService.getRecurringPricesFromStripe();
    profile = userController.profile;
    profileType.value = profile.type;
    initializeSubscriptions();
  }

  Future<void> initializeSubscriptions() async {
    subscriptionPlans = await SubscriptionPlanFirestore().getAll();
    if(subscriptionPlans.isNotEmpty) {
      for(SubscriptionPlan plan in subscriptionPlans.values) {
        StripePrice? stripePrice = await StripeService.getPrice(plan.priceId);
        if(stripePrice != null) {
          plan.price = Price.fromStripe(stripePrice);
        }
      }

      setProfileTypePlans();
    }
  }

  @override
  void onReady() async {
    setActiveSubscriptions();
    isLoading.value = false;
    update();
  }

  void setProfileTypePlans() {
    profilePlans.clear();
    profilePlans.addAll(subscriptionPlans);
    switch(profileType.value) {
      case ProfileType.general:
        profilePlans.removeWhere((s, p) =>
        p.level == SubscriptionLevel.creator
            || p.level == SubscriptionLevel.connect
            || p.level == SubscriptionLevel.artist
            || p.level == SubscriptionLevel.professional
            || p.level == SubscriptionLevel.premium
            || p.level == SubscriptionLevel.publish
        );
      case ProfileType.appArtist:
        profilePlans.removeWhere((s, p) =>
        p.level == SubscriptionLevel.basic
            || p.level == SubscriptionLevel.connect
        );
      case ProfileType.facilitator:
      case ProfileType.host:
      // case ProfileType.researcher:
      case ProfileType.band:
      profilePlans.removeWhere((s, p) =>
      p.level == SubscriptionLevel.creator
          || p.level == SubscriptionLevel.artist
          || p.level == SubscriptionLevel.publish
      );
      default:
        break;
    }

    selectedPlan = profilePlans.values.first;
    selectedPlanName.value = selectedPlan.name;
    selectedPlanImgUrl.value = selectedPlan.imgUrl;
    if(selectedPlan.price != null) {
      selectedPrice.value = selectedPlan.price!;
    }
  }

  Future<void> paySubscription(SubscriptionPlan subscriptionPlan, String fromRoute) async {
    AppConfig.logger.d("Entering paySusbscription Method");

    try {
      Get.toNamed(AppRouteConstants.orderConfirmation, arguments: [subscriptionPlan, fromRoute, profileType.value]);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  Future<void> cancelSubscription() async {
    AppConfig.logger.d("Entering paySusbscription Method");

    try {
      if(userController.userSubscription?.subscriptionId.isNotEmpty ?? false) {
        if(await StripeService.cancelSubscription(userController.userSubscription!.subscriptionId)) {
          userController.updateSubscriptionId('');
          UserSubscriptionFirestore().cancel(userController.userSubscription!.subscriptionId);
          userController.userSubscription = null;
          Get.offAllNamed(AppRouteConstants.home);
          Get.snackbar(
              'Suscripción Cancelada Satisfactoriamente',
              'Tu suscripción a ${('${userController.userSubscription?.level?.name ?? ''} Plan').tr} fue cancelada.',
              snackPosition: SnackPosition.bottom,
          );
        } else {

        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  void changeSubscriptionPlan(String planId) {
    AppConfig.logger.d("Changing Subscription PLan to: $planId");

    if(selectedPlan.price != null) {
      selectedPlan = subscriptionPlans[planId]!;
      selectedPlanName.value = selectedPlan.name;
      selectedPlanImgUrl.value = selectedPlan.imgUrl;
      selectedPrice.value = selectedPlan.price!;
    }

    update();
  }

  void selectProfileType(ProfileType type) {
    try {
      profileType.value = type;
      setProfileTypePlans();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  void selectFacilityType(FacilityType type) {
    try {
      facilityType.value = type;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  void selectPlaceType(PlaceType type) {
    try {
      placeType.value = type;
      setProfileTypePlans();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  Future<void> updateProfileType() async {
    try {
      if(profileType.value != profile.type && profile.id.isNotEmpty) {
        if(await ProfileFirestore().updateType(profile.id, profileType.value)) {
          Get.back();
          Get.snackbar(
            CoreConstants.updateProfileType.tr,
            CoreConstants.updateProfileTypeSuccess.tr,
            snackPosition: SnackPosition.bottom,
          );

          userController.profile.type = profileType.value;
          profile.type = profileType.value;
        }

      } else {
        Get.snackbar(
          CoreConstants.updateProfileType.tr,
          CoreConstants.updateProfileTypeSuccess.tr,
          snackPosition: SnackPosition.bottom,
        );
      }


    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  double getSubscriptionPrice(SubscriptionLevel level) {

    subscriptionPlans.forEach((key, plan) {
      if(plan.level == level) {
        selectedPlan = plan;
        selectedPlanName.value = selectedPlan.name;
        selectedPlanImgUrl.value = selectedPlan.imgUrl;
        selectedPrice.value = selectedPlan.price!;
      }
    });

    return selectedPrice.value.amount;
  }

  Future<void> setActiveSubscriptions() async {
    if(activeSubscriptions.isEmpty) {
      List<UserSubscription> subscriptions = await UserSubscriptionFirestore().getAll();
      if(subscriptions.isNotEmpty) {
        for(UserSubscription subscription in subscriptions) {
          if(subscription.status == SubscriptionStatus.active && subscription.level != null) {
            if(activeSubscriptions[subscription.level] == null) {
              activeSubscriptions[subscription.level!] = [];
            }
            activeSubscriptions[subscription.level]?.add(subscription);
          }
        }
      }
    } else {
      AppConfig.logger.d("Active Subscriptions already loaded");
    }
  }

}
