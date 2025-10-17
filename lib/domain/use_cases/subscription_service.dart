import '../../domain/model/subscription_plan.dart';
import '../../utils/enums/facilitator_type.dart';
import '../../utils/enums/place_type.dart';
import '../../utils/enums/profile_type.dart';
import '../../utils/enums/subscription_level.dart';
import '../model/price.dart';
import '../model/user_subscription.dart';

abstract class SubscriptionService {

  Future<void> initializeSubscriptions();
  void setProfileTypePlans();
  Future<void> paySubscription(SubscriptionPlan subscriptionPlan, String fromRoute);
  Future<void> cancelSubscription();
  void changeSubscriptionPlan(String planId);
  void selectProfileType(ProfileType type);
  void selectFacilityType(FacilityType type);
  void selectPlaceType(PlaceType type);
  Future<void> updateProfileType();
  double getSubscriptionPrice(SubscriptionLevel level);
  Future<void> setActiveSubscriptions();
  List<UserSubscription> getActiveSubscriptions({SubscriptionLevel? targetLevel, int targetMonth, int targetYear});

  Map<String, SubscriptionPlan> get subscriptionPlans;

  String get selectedPlanName;
  String get selectedPlanImgUrl;
  Price get selectedPrice;
  SubscriptionPlan get selectedPlan;

  bool get isLoading;
  ProfileType get profileType;
  Map<String, SubscriptionPlan> get profilePlans;

  Map<SubscriptionLevel,List<UserSubscription>> get activeSubscriptions;

}
