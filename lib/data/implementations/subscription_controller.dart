import 'package:flutter/foundation.dart';
import 'package:sint/sint.dart';

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
import '../../utils/neom_error_logger.dart';
import '../firestore/user_subscription_firestore.dart';

class SubscriptionController extends SintController implements SubscriptionService {

  final userServiceImpl = Sint.find<UserService>();
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
      // Filter by environment: debug=test plans only, release=live plans only.
      // Role does NOT affect which environment is used — admins in debug
      // should still see test plans to avoid hitting the live Stripe API.
      final isLiveMode = !kDebugMode;
      _subscriptionPlans.removeWhere((_, plan) => plan.isLive != isLiveMode);

      final keysToRemove = <String>[];

      for(final entry in _subscriptionPlans.entries) {
        final plan = entry.value;
        StripePrice? stripePrice = await Sint.find<StripeApiService>().getPrice(plan.priceId);
        if(stripePrice != null) {
          plan.price = Price.fromStripe(stripePrice);
        } else {
          // Price could not be fetched — plan belongs to the other Stripe
          // environment (test vs live). Remove it so only valid plans show.
          AppConfig.logger.w('Plan "${entry.key}" skipped: priceId ${plan.priceId} not found in current Stripe environment');
          keysToRemove.add(entry.key);
        }
      }

      for (final key in keysToRemove) {
        _subscriptionPlans.remove(key);
      }

      if(_subscriptionPlans.isNotEmpty) {
        setProfileTypePlans();
      }
    }

    await setActiveSubscriptions();
    _isLoading.value = false;
  }

  @override
  void onReady() async {

  }

  @override
  void setProfileTypePlans() {
    AppConfig.logger.d("Setting Profile Type Plans for: ${_profileType.value.name}");
    _profilePlans.clear();
    _profilePlans.addAll(_subscriptionPlans);
    switch(_profileType.value) {
      case ProfileType.general:
        _profilePlans.removeWhere((s, p) =>
        (p.level?.value ?? 0) > SubscriptionLevel.family.value);
      case ProfileType.appArtist:
        _profilePlans.removeWhere((s, p) =>
        (p.level?.value ?? 0) < SubscriptionLevel.creator.value);
      case ProfileType.facilitator:
      case ProfileType.host:
        _profilePlans.removeWhere((s, p) {
          final lv = p.level?.value ?? 0;
          return lv != SubscriptionLevel.basic.value
              && lv != SubscriptionLevel.professional.value
              && lv != SubscriptionLevel.premium.value;
        });
      // case ProfileType.researcher:
      case ProfileType.band:
      _profilePlans.removeWhere((s, p) =>
      (p.level?.value ?? 0) < SubscriptionLevel.professional.value);
      default:
        break;
    }

    if (_profilePlans.isEmpty) {
      AppConfig.logger.w('No plans available for profile type: $profileType');
      return;
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
      Sint.toNamed(AppRouteConstants.orderConfirmation, arguments: [subscriptionPlan, fromRoute, profileType]);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'paySubscription');
    }

    update();
  }

  @override
  Future<void> cancelSubscription() async {
    AppConfig.logger.d("Cancelling Subscription");

    try {
      final subscription = userServiceImpl.userSubscription;
      if (subscription == null || subscription.subscriptionId.isEmpty) return;

      final planName = subscription.level?.name ?? '';
      final periodEndSeconds = await Sint.find<StripeApiService>().cancelSubscription(subscription.subscriptionId);

      if (periodEndSeconds > 0) {
        // Stripe will keep the subscription active until period end
        final endDateMs = periodEndSeconds * 1000;
        subscription.endDate = endDateMs;

        // Store scheduled cancellation in Firestore (keeps status active until end date)
        UserSubscriptionFirestore().scheduleCancellation(subscription.subscriptionId, endDateMs);

        final endDate = DateTime.fromMillisecondsSinceEpoch(endDateMs);
        final formattedDate = '${endDate.day}/${endDate.month}/${endDate.year}';

        AppConfig.logger.i('Subscription $planName scheduled to cancel on $formattedDate');

        Sint.snackbar(
          'cancellationScheduled'.tr,
          'subscriptionActiveUntil'.tr
              .replaceAll('@plan', planName)
              .replaceAll('@date', formattedDate),
          snackPosition: SnackPosition.bottom,
          duration: const Duration(seconds: 5),
        );
      } else {
        AppConfig.logger.e('Failed to cancel subscription with Stripe');
        Sint.snackbar(
          'error'.tr,
          'cancellationError'.tr,
          snackPosition: SnackPosition.bottom,
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'cancelSubscription');
    }

    update();
  }

  @override
  void changeSubscriptionPlan(String planId) {
    AppConfig.logger.d("Changing Subscription Plan to: $planId");

    try {
      // Look up by map key first, then by plan.id field as fallback
      SubscriptionPlan? plan = _subscriptionPlans[planId];
      plan ??= _subscriptionPlans.values.where((p) => p.id == planId).firstOrNull;

      if(plan != null && plan.price != null) {
        _selectedPlan = plan;
        _selectedPlanName.value = selectedPlan.name;
        _selectedPlanImgUrl.value = selectedPlan.imgUrl;
        _selectedPrice.value = selectedPlan.price!;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'changeSubscriptionPlan');
    }

    update();
  }

  @override
  void selectProfileType(ProfileType type) {
    AppConfig.logger.d("Selecting Profile Type: ${type.name}");

    try {
      _profileType.value = type;
      setProfileTypePlans();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'selectProfileType');
    }
  }

  @override
  void selectFacilityType(FacilityType type) {
    AppConfig.logger.d("Selecting Facility Type: ${type.name}");

    try {
      facilityType.value = type;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'selectFacilityType');
    }

  }

  @override
  void selectPlaceType(PlaceType type) {
    AppConfig.logger.d("Selecting Place Type: ${type.name}");

    try {
      placeType.value = type;
      setProfileTypePlans();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'selectPlaceType');
    }

  }

  @override
  Future<void> updateProfileType() async {
    AppConfig.logger.d("Updating Profile Type to: ${_profileType.value.name}");

    try {
      if(_profileType.value != profile.type && profile.id.isNotEmpty) {
        if(await ProfileFirestore().updateType(profile.id, _profileType.value)) {
          Sint.back();
          Sint.snackbar(
            CoreConstants.updateProfileType.tr,
            CoreConstants.updateProfileTypeSuccess.tr,
            snackPosition: SnackPosition.bottom,
          );

          userServiceImpl.profile.type = _profileType.value;
          profile.type = _profileType.value;
        }

      } else {
        Sint.snackbar(
          CoreConstants.updateProfileType.tr,
          CoreConstants.updateProfileTypeSuccess.tr,
          snackPosition: SnackPosition.bottom,
        );
      }


    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'updateProfileType');
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
        if(kDebugMode) {
          _selectedPrice.value = Price(amount: 59);
        } else {
          _selectedPrice.value = selectedPlan.price!;
        }

      }
    });

    return _selectedPrice.value.amount;
  }

  @override
  Future<void> setActiveSubscriptions() async {
    AppConfig.logger.d("Setting Active Subscriptions");

    if(_activeSubscriptions.isEmpty) {
      await _loadActiveSubscriptions();
    } else {
      AppConfig.logger.d("Active Subscriptions already loaded");
    }
  }

  @override
  Future<void> refreshActiveSubscriptions() async {
    AppConfig.logger.d("Refreshing Active Subscriptions (forced reload)");
    _activeSubscriptions.clear();
    await _loadActiveSubscriptions();
  }

  Future<void> _loadActiveSubscriptions() async {
    List<UserSubscription> subscriptions = await UserSubscriptionFirestore().getAll();
    if(subscriptions.isNotEmpty) {
      for(UserSubscription subscription in subscriptions) {
        if(subscription.status == SubscriptionStatus.active && subscription.level != null) {
          if(_activeSubscriptions[subscription.level] == null) {
            _activeSubscriptions[subscription.level!] = [];
          }
          _activeSubscriptions[subscription.level]?.add(subscription);
        }
      }
    }
  }

  @override
  List<UserSubscription> getActiveSubscriptions({SubscriptionLevel? targetLevel, int? targetMonth, int? targetYear}) {
    AppConfig.logger.d("Checking ${targetLevel?.name} Active Subscriptions for: $targetMonth/$targetYear");

    List<UserSubscription> activeSubs = [];
    int month = targetMonth ?? DateTime.now().month;
    int year = targetYear ?? DateTime.now().year;

    _activeSubscriptions.forEach((level, subscriptions) {

      if(targetLevel != null && level != targetLevel) return;

      for(UserSubscription subscription in subscriptions) {

        int startDateMonth = 0;
        int startDateYear = 0;
        int endDateMonth = 0;
        int endDateYear = 0;
        bool isActive = true;

        if(subscription.startDate != 0) {
          startDateMonth = DateTime.fromMillisecondsSinceEpoch(subscription.startDate).month;
          startDateYear = DateTime.fromMillisecondsSinceEpoch(subscription.startDate).year;
        }

        bool startedOnOrBeforeTargetMonth = (startDateYear < year) ||
            (startDateYear == year && startDateMonth <= month);

        if(startedOnOrBeforeTargetMonth) {
          if(subscription.endDate != 0) {
            endDateMonth = DateTime.fromMillisecondsSinceEpoch(subscription.endDate).month;
            endDateYear = DateTime.fromMillisecondsSinceEpoch(subscription.endDate).year;
            bool endedBeforeTargetMonth = (endDateYear < year) || (endDateYear == year && endDateMonth < month);
            if(endedBeforeTargetMonth) isActive = false;
          }
        } else {
          isActive = false;
        }

        if(isActive) {
          AppConfig.logger.d("Subscription ${subscription.subscriptionId} of level ${subscription.level?.name} was active in $month/$year");
          activeSubs.add(subscription);
        }
      }
    });

    return activeSubs;
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
