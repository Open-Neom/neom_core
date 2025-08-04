import 'package:get/get.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/price.dart';
import '../../domain/model/stripe/stripe_price.dart';
import '../../domain/model/subscription_plan.dart';
import '../../domain/model/user_subscription.dart';
import '../../domain/use_cases/stripe_api_service.dart';
import '../../domain/use_cases/subscription_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/core_constants.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import '../firestore/profile_firestore.dart';
import '../firestore/subscription_plan_firestore.dart';
import '../firestore/user_subscription_firestore.dart';

class SubscriptionController extends GetxController implements SubscriptionService {

  final userServiceImpl = Get.find<UserService>();
  AppProfile profile = AppProfile();

  final RxBool _isLoading = true.obs;
  final Rx<String> _selectedPlanName = ''.obs;
  final Rx<String> _selectedPlanImgUrl = ''.obs;
  final Rx<Price> _selectedPrice = Price().obs;
  SubscriptionPlan _selectedPlan = SubscriptionPlan();
  Map<String, SubscriptionPlan> _subscriptionPlans = {};
  final RxMap<String, SubscriptionPlan> _profilePlans = <String, SubscriptionPlan>{}.obs;
  final Rx<ProfileType>  _profileType = ProfileType.general.obs;

  final RxMap<SubscriptionLevel,List<UserSubscription>> _activeSubscriptions = <SubscriptionLevel,List<UserSubscription>>{}.obs;
  Rx<FacilityType>  facilityType = FacilityType.general.obs;
  Rx<PlaceType>  placeType = PlaceType.general.obs;


  @override
  void onInit() {
    super.onInit();
    profile = userServiceImpl.profile;
    _profileType.value = profile.type;
    initializeSubscriptions();
  }

  @override
  Future<void> initializeSubscriptions() async {
    AppConfig.logger.t("Initializing Subscriptions");
    _subscriptionPlans = await SubscriptionPlanFirestore().getAll();
    if(_subscriptionPlans.isNotEmpty) {
      for(SubscriptionPlan plan in _subscriptionPlans.values) {
        StripePrice? stripePrice = await Get.find<StripeApiService>().getPrice(plan.priceId);
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
    _isLoading.value = false;
    update();
  }

  @override
  void setProfileTypePlans() {
    AppConfig.logger.d("Setting Profile Type Plans for: ${_profileType.value.name}");
    _profilePlans.clear();
    _profilePlans.addAll(_subscriptionPlans);
    switch(_profileType.value) {
      case ProfileType.general:
        _profilePlans.removeWhere((s, p) =>
        p.level == SubscriptionLevel.creator
            || p.level == SubscriptionLevel.connect
            || p.level == SubscriptionLevel.artist
            || p.level == SubscriptionLevel.professional
            || p.level == SubscriptionLevel.premium
            || p.level == SubscriptionLevel.publish
        );
      case ProfileType.appArtist:
        _profilePlans.removeWhere((s, p) =>
        p.level == SubscriptionLevel.basic
            || p.level == SubscriptionLevel.connect
        );
      case ProfileType.facilitator:
      case ProfileType.host:
      // case ProfileType.researcher:
      case ProfileType.band:
      _profilePlans.removeWhere((s, p) =>
      p.level == SubscriptionLevel.creator
          || p.level == SubscriptionLevel.artist
          || p.level == SubscriptionLevel.publish
      );
      default:
        break;
    }

    _selectedPlan = _profilePlans.values.first;
    _selectedPlanName.value = selectedPlan.name;
    _selectedPlanImgUrl.value = selectedPlan.imgUrl;
    if(selectedPlan.price != null) {
      _selectedPrice.value = selectedPlan.price!;
    }
  }

  @override
  Future<void> paySubscription(SubscriptionPlan subscriptionPlan, String fromRoute) async {
    AppConfig.logger.d("Paying Subscription for: ${subscriptionPlan.name} from route: $fromRoute");

    try {
      Get.toNamed(AppRouteConstants.orderConfirmation, arguments: [subscriptionPlan, fromRoute, profileType.value]);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    update();
  }

  @override
  Future<void> cancelSubscription() async {
    AppConfig.logger.d("Cancelling Subscription");

    try {
      if(userServiceImpl.userSubscription?.subscriptionId.isNotEmpty ?? false) {
        if(await Get.find<StripeApiService>().cancelSubscription(userServiceImpl.userSubscription!.subscriptionId)) {
          userServiceImpl.updateSubscriptionId('');
          UserSubscriptionFirestore().cancel(userServiceImpl.userSubscription!.subscriptionId);
          userServiceImpl.userSubscription = null;
          Get.offAllNamed(AppRouteConstants.home);
          Get.snackbar(
              'Suscripción Cancelada Satisfactoriamente',
              'Tu suscripción a ${('${userServiceImpl.userSubscription?.level?.name ?? ''} Plan').tr} fue cancelada.',
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

  @override
  void changeSubscriptionPlan(String planId) {
    AppConfig.logger.d("Changing Subscription PLan to: $planId");

    if(selectedPlan.price != null) {
      _selectedPlan = _subscriptionPlans[planId]!;
      _selectedPlanName.value = selectedPlan.name;
      _selectedPlanImgUrl.value = selectedPlan.imgUrl;
      _selectedPrice.value = selectedPlan.price!;
    }

    update();
  }

  @override
  void selectProfileType(ProfileType type) {
    AppConfig.logger.d("Selecting Profile Type: ${type.name}");

    try {
      _profileType.value = type;
      setProfileTypePlans();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  void selectFacilityType(FacilityType type) {
    AppConfig.logger.d("Selecting Facility Type: ${type.name}");

    try {
      facilityType.value = type;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void selectPlaceType(PlaceType type) {
    AppConfig.logger.d("Selecting Place Type: ${type.name}");

    try {
      placeType.value = type;
      setProfileTypePlans();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> updateProfileType() async {
    AppConfig.logger.d("Updating Profile Type to: ${_profileType.value.name}");

    try {
      if(_profileType.value != profile.type && profile.id.isNotEmpty) {
        if(await ProfileFirestore().updateType(profile.id, _profileType.value)) {
          Get.back();
          Get.snackbar(
            CoreConstants.updateProfileType.tr,
            CoreConstants.updateProfileTypeSuccess.tr,
            snackPosition: SnackPosition.bottom,
          );

          userServiceImpl.profile.type = _profileType.value;
          profile.type = _profileType.value;
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

  @override
  double getSubscriptionPrice(SubscriptionLevel level) {
    AppConfig.logger.d("Getting Subscription Price for Level: ${level.name}");

    _subscriptionPlans.forEach((key, plan) {
      if(plan.level == level) {
        _selectedPlan = plan;
        _selectedPlanName.value = selectedPlan.name;
        _selectedPlanImgUrl.value = selectedPlan.imgUrl;
        _selectedPrice.value = selectedPlan.price!;
      }
    });

    return _selectedPrice.value.amount;
  }

  @override
  Future<void> setActiveSubscriptions() async {
    AppConfig.logger.d("Setting Active Subscriptions");

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

  @override
  Map<String, SubscriptionPlan> get subscriptionPlans => _subscriptionPlans;

  @override
  SubscriptionPlan get selectedPlan => _selectedPlan;

  @override
  String get selectedPlanImgUrl => _selectedPlanImgUrl.value;

  @override
  String get selectedPlanName => _selectedPlanName.value;

  @override
  Price get selectedPrice => _selectedPrice.value;

  @override
  bool get isLoading => _isLoading.value;

  @override
  ProfileType get profileType => _profileType.value;

  @override
  Map<String, SubscriptionPlan> get profilePlans => _profilePlans;

  @override
  Map<SubscriptionLevel, List<UserSubscription>> get activeSubscriptions => _activeSubscriptions.value;

}
