import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sint/sint.dart';

import '../../app_config.dart';
import '../../app_properties.dart';
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
import '../../utils/enums/app_currency.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import '../../utils/enums/user_role.dart';
import '../../utils/neom_error_logger.dart';
import '../api/app_platform_api.dart';
import '../firestore/profile_firestore.dart';
import '../firestore/subscription_plan_firestore.dart';
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
    if (AppPlatformApi.isEnabled) {
      try {
        final plans = await AppPlatformApi.client('subscriptions').read<List<SubscriptionPlan>>(
          'getPlans',
          const {},
          decode: (res) {
            final raw = res['items'];
            if (raw is List) {
              return raw
                  .map((e) => SubscriptionPlan.fromJSON(Map<String, dynamic>.from(e as Map)))
                  .toList();
            }
            return <SubscriptionPlan>[];
          },
          fallback: () => <SubscriptionPlan>[],
        );
        if (plans.isNotEmpty) {
          _subscriptionPlans = {for (final p in plans.where((p) => p.isActive)) p.id: p};
        } else {
          final fallbackPrice = AppProperties.getSubscriptionPrice().amount > 0
              ? AppProperties.getSubscriptionPrice().amount
              : 80.0;
          final defaultPlan = SubscriptionPlan(
            id: 'gig_music_monthly',
            name: 'Gig Music',
            level: SubscriptionLevel.basic,
            price: Price(amount: fallbackPrice, currency: AppCurrency.mxn),
            isActive: true,
            isLive: true,
          );
          _subscriptionPlans = {defaultPlan.id: defaultPlan};
        }
        setProfileTypePlans();
        await setActiveSubscriptions();
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'initializeSubscriptions.platform');
      } finally {
        _isLoading.value = false;
      }
      return;
    }

    _subscriptionPlans = await SubscriptionPlanFirestore().getAll();
    if(_subscriptionPlans.isNotEmpty) {
      // Filter by environment: debug=test plans only, release=live plans only.
      // Role does NOT affect which environment is used — admins in debug
      // should still see test plans to avoid hitting the live Stripe API.
      final isLiveMode = !kDebugMode;
      _subscriptionPlans.removeWhere((_, plan) => plan.isLive != isLiveMode || !plan.isActive);

      final keysToRemove = <String>[];

      for(final entry in _subscriptionPlans.entries) {
        final plan = entry.value;
        StripePrice? stripePrice = await Sint.find<StripeApiService>().getPrice(plan.priceId);
        if(stripePrice != null && stripePrice.active) {
          plan.price = Price.fromStripe(stripePrice);
        } else {
          // Price could not be fetched or is archived in Stripe — omit from checkout.
          AppConfig.logger.w('Plan "${entry.key}" skipped: priceId ${plan.priceId} unavailable or inactive in current Stripe environment');
          keysToRemove.add(entry.key);
          continue;
        }

        // Optional yearly price
        if (plan.priceIdYearly.isNotEmpty) {
          try {
            final yearlyStripe = await Sint.find<StripeApiService>().getPrice(plan.priceIdYearly);
            if (yearlyStripe != null) {
              plan.priceYearly = Price.fromStripe(yearlyStripe);
            }
          } catch (e) {
            AppConfig.logger.w('Yearly price not available for plan "${entry.key}": $e');
          }
        }
      }

      for (final key in keysToRemove) {
        _subscriptionPlans.remove(key);
      }

      // Enrich founder plans with remaining seats from Firestore counters
      await _loadFounderCounters();

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
    if (AppConfig.instance.appInUse != AppInUse.g) {
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
        case ProfileType.collective:
        _profilePlans.removeWhere((s, p) =>
        (p.level?.value ?? 0) < SubscriptionLevel.professional.value);
        default:
          break;
      }
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
      if (AppPlatformApi.isEnabled) {
        final origin = kIsWeb ? Uri.base.origin : 'https://gigmeout.com';
        final session = await AppPlatformApi.client('subscriptions').mutate(
          'createCheckoutSession',
          {
            'purpose': 'gig_music_subscription',
            'originUrl': origin,
            'metadata': {'planId': subscriptionPlan.id},
          },
          durable: false,
        );
        if (session is Map) {
          if (session['sandbox'] == true) {
            final verified = await AppPlatformApi.client('payments').mutate(
              'verifyCheckoutSession',
              {
                'localSessionId': session['sessionId'],
                'sandboxToken': session['sandboxToken'],
              },
              durable: false,
            );
            if (verified is Map && verified['subscription'] is Map) {
              final sub = UserSubscription.fromJSON(
                Map<String, dynamic>.from(verified['subscription'] as Map),
              );
              userServiceImpl.userSubscription = sub;
              userServiceImpl.user.subscriptionId = sub.subscriptionId;
            }
            await refreshActiveSubscriptions();
            Sint.snackbar(
              '¡Gig Music Activado!',
              'Ya tienes escucha continua sin interrupción de tiempo e impulsas CASETE.',
              snackPosition: SnackPosition.bottom,
              duration: const Duration(seconds: 4),
            );
            update();
            return;
          } else if (session['checkoutUrl']?.toString().isNotEmpty ?? false) {
            subscriptionPlan.href = session['checkoutUrl'].toString();
            update();
            return;
          }
        }
      }
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
        if (!AppPlatformApi.isEnabled) {
          UserSubscriptionFirestore().scheduleCancellation(subscription.subscriptionId, endDateMs);
        }

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
        if(kDebugMode && selectedPlan.price == null) {
          final fallbackAmount = AppProperties.getSubscriptionPrice().amount;
          _selectedPrice.value = Price(amount: fallbackAmount > 0 ? fallbackAmount : 80);
        } else if (selectedPlan.price != null) {
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

  /// Reads `/founders_counters/{tier}` for every plan that carries a
  /// `founderTier` slug and patches `founderSeatsRemaining`/`founderSeatsTotal`.
  ///
  /// Expected counter doc shape:
  /// `{ seatsTotal: 200, seatsSold: int, closed: bool }`.
  Future<void> _loadFounderCounters() async {
    try {
      final founderPlans = _subscriptionPlans.values.where((p) => p.isFounderPlan).toList();
      if (founderPlans.isEmpty) return;

      final db = FirebaseFirestore.instance;
      for (final plan in founderPlans) {
        try {
          final snap = await db.doc('founders_counters/${plan.founderTier}').get();
          if (!snap.exists) continue;
          final data = snap.data() ?? const <String, dynamic>{};
          final total = (data['seatsTotal'] as num?)?.toInt() ?? 0;
          final sold = (data['seatsSold'] as num?)?.toInt() ?? 0;
          plan.founderSeatsTotal = total;
          plan.founderSeatsRemaining = (total - sold).clamp(0, total);
        } catch (e) {
          AppConfig.logger.w('Failed to load founder counter ${plan.founderTier}: $e');
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadFounderCounters');
    }
  }

  Future<void> _loadActiveSubscriptions() async {
    if (AppPlatformApi.isEnabled) {
      try {
        final subs = await AppPlatformApi.client('subscriptions').read<List<UserSubscription>>(
          'getMySubscription',
          const {},
          decode: (res) {
            final raw = res['items'];
            if (raw is List) {
              return raw
                  .map((e) => UserSubscription.fromJSON(Map<String, dynamic>.from(e as Map)))
                  .toList();
            }
            return <UserSubscription>[];
          },
          fallback: () => <UserSubscription>[],
        );
        for (final subscription in subs) {
          if (subscription.status == SubscriptionStatus.active && subscription.level != null) {
            _activeSubscriptions.putIfAbsent(subscription.level!, () => []).add(subscription);
            userServiceImpl.userSubscription = subscription;
            if (subscription.subscriptionId.isNotEmpty) {
              userServiceImpl.user.subscriptionId = subscription.subscriptionId;
            }
          }
        }
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: '_loadActiveSubscriptions.platform');
      }
      return;
    }

    try {
      final userRole = userServiceImpl.user.userRole;
      if (userRole != UserRole.admin && userRole != UserRole.superAdmin) {
        // Non-staff sessions: guard against querying all user subscriptions which fails with PERMISSION_DENIED.
        // Instead, safely register current user's active subscription if available.
        final userSub = userServiceImpl.userSubscription;
        if (userSub != null && userSub.status == SubscriptionStatus.active && userSub.level != null) {
          _activeSubscriptions[userSub.level!] = [userSub];
        }
        return;
      }
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'loadActiveSubscriptions');
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
