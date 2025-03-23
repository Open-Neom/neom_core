import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../neom_commons.dart';
import '../../domain/model/stripe/stripe_price.dart';
import '../../domain/model/subscription_plan.dart';
import '../../ui/widgets/handled_cached_network_image.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import '../api_services/stripe/stripe_service.dart';
import '../firestore/subscription_plan_firestore.dart';
import '../firestore/user_subscription_firestore.dart';

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

  Rx<ProfileType>  profileType = ProfileType.general.obs;
  Rx<FacilityType>  facilityType = FacilityType.general.obs;
  Rx<PlaceType>  placeType = PlaceType.general.obs;


  @override
  void onInit() async {
    super.onInit();
    // Map<String, List<StripePrice>> recurringPrices = await StripeService.getRecurringPricesFromStripe();
    profile = userController.profile;
    profileType.value = profile.type;
    if(userController.userSubscription?.status != SubscriptionStatus.active && subscriptionPlans.isEmpty) {
      await initializeSubscriptions();
    }

    isLoading.value = false;
    // SubscriptionPlanFirestore().insertSubscriptionPlans();
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

  @override
  void onReady() async {
    update([AppPageIdConstants.accountSettings]);
  }

  Future<bool?> getSubscriptionAlert(BuildContext context, String fromRoute) async {
    AppUtilities.logger.d("getSubscriptionAlert");
    // selectedPrice.value = AppFlavour.getSubscriptionPrice();
    List<ProfileType> profileTypes = List.from(ProfileType.values);
    profileTypes.removeWhere((type) => type == ProfileType.broadcaster);
    switch(AppFlavour.appInUse) {
      case AppInUse.g:
        profileTypes.removeWhere((type) => type == ProfileType.band);
        profileTypes.removeWhere((type) => type == ProfileType.researcher);
      case AppInUse.e:
        profileTypes.removeWhere((type) => type == ProfileType.band);
        profileTypes.removeWhere((type) => type == ProfileType.researcher);
      case AppInUse.c:
        profileTypes.removeWhere((type) => type == ProfileType.band);
    }

    if(subscriptionPlans.isEmpty) await initializeSubscriptions();

    return Alert(
        context: context,
        style: AlertStyle(
            backgroundColor: AppColor.main50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            titleTextAlign: TextAlign.justify
        ),
        content: Obx(() => isLoading.value ? const Center(child: CircularProgressIndicator()) : Column(
          children: <Widget>[
            AppTheme.heightSpace20,
            Text(('${selectedPlanName.value}Msg').tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),textAlign: TextAlign.justify,),
            AppTheme.heightSpace20,
            HandledCachedNetworkImage(selectedPlanImgUrl.value),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.profileType.tr}: ",
                  style: const TextStyle(fontSize: 15),
                ),
                DropdownButton<ProfileType>(
                  items: profileTypes.map((ProfileType type) {
                    return DropdownMenuItem<ProfileType>(
                      value: type,
                      child: Text(type.value.tr.capitalize),
                    );
                  }).toList(),
                  onChanged: (ProfileType? selectedType) {
                    if (selectedType == null) return;
                    selectProfileType(selectedType);
                  },
                  value: profileType.value,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.getMain(),
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            ///VERIFY TO DELETE
            // if(profileType.value == ProfileType.facilitator) Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text("${AppTranslationConstants.type.tr}: ",
            //       style: const TextStyle(fontSize: 15),
            //     ),
            //     DropdownButton<FacilityType>(
            //       items: FacilityType.values.map((FacilityType type) {
            //         return DropdownMenuItem<FacilityType>(
            //           value: type,
            //           child: Text(type.value.tr.capitalize),
            //         );
            //       }).toList(),
            //       onChanged: (FacilityType? selectedType) {
            //         if (selectedType == null) return;
            //         selectFacilityType(selectedType);
            //       },
            //       value: facilityType.value,
            //       alignment: Alignment.center,
            //       icon: const Icon(Icons.arrow_downward),
            //       iconSize: 20,
            //       elevation: 16,
            //       style: const TextStyle(color: Colors.white),
            //       dropdownColor: AppColor.getMain(),
            //       underline: Container(
            //         height: 1,
            //         color: Colors.grey,
            //       ),
            //     ),
            //   ],
            // ),
            // if(profileType.value == ProfileType.host) Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text("${AppTranslationConstants.type.tr}: ",
            //       style: const TextStyle(fontSize: 15),
            //     ),
            //     DropdownButton<PlaceType>(
            //       items: PlaceType.values.map((PlaceType type) {
            //         return DropdownMenuItem<PlaceType>(
            //           value: type,
            //           child: Text(type.value.tr.capitalize),
            //         );
            //       }).toList(),
            //       onChanged: (PlaceType? selectedType) {
            //         if (selectedType == null) return;
            //         selectPlaceType(selectedType);
            //       },
            //       value: placeType.value,
            //       alignment: Alignment.center,
            //       icon: const Icon(Icons.arrow_downward),
            //       iconSize: 20,
            //       elevation: 16,
            //       style: const TextStyle(color: Colors.white),
            //       dropdownColor: AppColor.getMain(),
            //       underline: Container(
            //         height: 1,
            //         color: Colors.grey,
            //       ),
            //     ),
            //   ],
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.subscription.tr}: ",
                  style: const TextStyle(fontSize: 15),
                ),
                DropdownButton<String>(
                  items: profilePlans.values.map((SubscriptionPlan plan) {
                    return DropdownMenuItem<String>(
                      value: plan.id,
                      child: Text(plan.name.tr),
                    );
                  }).toList(),
                  onChanged: (String? plan) {
                    if(plan != null) {
                      changeSubscriptionPlan(plan);
                    }
                  },
                  value: selectedPlan.id,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 20,
                  elevation: 16,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: AppColor.getMain(),
                  underline: Container(
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.totalToPay.tr.capitalizeFirst}:",
                  style: const TextStyle(fontSize: 15),
                ),
                Row(
                  children: [
                    Text("${CoreUtilities.getCurrencySymbol(selectedPrice.value.currency)} ${selectedPrice.value.amount} ${selectedPrice.value.currency.name.tr.toUpperCase()}",
                      style: const TextStyle(fontSize: 15),
                    ),
                    AppTheme.widthSpace5,
                  ],
                ),
              ],
            ),
          ],),
        ),
        buttons: [
          DialogButton(
            color: AppColor.bondiBlue75,
            onPressed: () async {
              await paySubscription(selectedPlan, fromRoute);
            },
            child: Text(AppTranslationConstants.confirmAndProceed.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ]
    ).show();
  }

  Future<void> paySubscription(SubscriptionPlan subscriptionPlan, String fromRoute) async {
    AppUtilities.logger.d("Entering paySusbscription Method");

    try {
      Get.toNamed(AppRouteConstants.orderConfirmation, arguments: [subscriptionPlan, fromRoute, profileType.value]);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails, AppPageIdConstants.bookDetails]);
  }

  Future<void> cancelSubscription() async {
    AppUtilities.logger.d("Entering paySusbscription Method");

    try {
      if(userController.userSubscription?.subscriptionId.isNotEmpty ?? false) {
        if(await StripeService.cancelSubscription(userController.userSubscription!.subscriptionId)) {
          userController.updateSubscriptionId('');
          UserSubscriptionFirestore().cancel(userController.userSubscription!.subscriptionId);
          userController.userSubscription = null;
          Get.offAllNamed(AppRouteConstants.home);
          AppUtilities.showSnackBar(
            title: 'Suscripción Cancelada Satisfactoriamente',
            message: 'Tu suscripción a ${('${userController.userSubscription?.level?.name ?? ''} Plan').tr} fue cancelada.'
                ' Sigue disfrutando de nuestro contenido de manera gratuita. '
                '¡Muchas gracias por utilizar EMXI',
            duration: const Duration(seconds: 6),
          );
        } else {

        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.appItemDetails, AppPageIdConstants.bookDetails, AppPageIdConstants.accountSettings]);
  }

  void changeSubscriptionPlan(String planId) {
    AppUtilities.logger.d("Changing Subscription PLan to: $planId");

    if(selectedPlan.price != null) {
      selectedPlan = subscriptionPlans[planId]!;
      selectedPlanName.value = selectedPlan.name;
      selectedPlanImgUrl.value = selectedPlan.imgUrl;
      selectedPrice.value = selectedPlan.price!;
    }

    update([AppPageIdConstants.accountSettings]);
  }

  @override
  void selectProfileType(ProfileType type) {
    try {
      profileType.value = type;
      setProfileTypePlans();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  void selectFacilityType(FacilityType type) {
    try {
      facilityType.value = type;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  void selectPlaceType(PlaceType type) {
    try {
      placeType.value = type;
      setProfileTypePlans();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> updateProfileType() async {
    try {
      if(profileType.value != profile.type && profile.id.isNotEmpty) {
        if(await ProfileFirestore().updateType(profile.id, profileType.value)) {
          Get.back();
          AppUtilities.showSnackBar(
              title: AppTranslationConstants.updateProfileType.tr,
              message: AppTranslationConstants.updateProfileTypeSuccess.tr);
          userController.profile.type = profileType.value;
          profile.type = profileType.value;
        }

      } else {
        AppUtilities.showSnackBar(
            title: AppTranslationConstants.updateProfileType.tr,
            message: AppTranslationConstants.updateProfileTypeSame.tr);
      }


    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }


}
