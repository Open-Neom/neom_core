import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../neom_commons.dart';
import '../../domain/model/stripe/stripe_price.dart';
import '../../domain/model/subscription_plan.dart';
import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import '../api_services/stripe/stripe_service.dart';
import '../firestore/subscription_plan_firestore.dart';
import '../firestore/user_subscription_firestore.dart';

class SubscriptionController extends GetxController with GetTickerProviderStateMixin {

  final userController = Get.find<UserController>();

  RxBool isLoading = true.obs;
  // Rx<SubscriptionLevel> selectedLevel = SubscriptionLevel.basic.obs;
  Rx<String> selectedPlanName = ''.obs;
  Rx<String> selectedPlanImgUrl = ''.obs;
  Rx<Price> selectedPrice = Price().obs;
  SubscriptionPlan selectedPlan = SubscriptionPlan();
  Map<String, SubscriptionPlan> subscriptionPlans = {};

  @override
  void onInit() async {
    super.onInit();
    // Map<String, List<StripePrice>> recurringPrices = await StripeService.getRecurringPricesFromStripe();
    if(userController.userSubscription?.status != SubscriptionStatus.active) {
      subscriptionPlans = await SubscriptionPlanFirestore().getAll();
    }

    if(subscriptionPlans.isNotEmpty) {
      switch(userController.profile.type) {
        case ProfileType.general:
          subscriptionPlans.removeWhere((s, p) =>
          p.level == SubscriptionLevel.creator
              || p.level == SubscriptionLevel.artist
              || p.level == SubscriptionLevel.professional
              || p.level == SubscriptionLevel.premium
              || p.level == SubscriptionLevel.publish
          );
        case ProfileType.artist:
          subscriptionPlans.removeWhere((s, p) =>
          p.level == SubscriptionLevel.basic
          );
        case ProfileType.facilitator:
        case ProfileType.host:
        // case ProfileType.researcher:
        case ProfileType.band:
        subscriptionPlans.removeWhere((s, p) =>
        p.level == SubscriptionLevel.creator
            || p.level == SubscriptionLevel.artist
            || p.level == SubscriptionLevel.publish
        );
        default:
          break;
      }

      for(SubscriptionPlan plan in subscriptionPlans.values) {
        StripePrice? stripePrice = await StripeService.getPrice(plan.priceId);
        if(stripePrice != null) {
          plan.price = Price.fromStripe(stripePrice);
        }
      }

      selectedPlan = subscriptionPlans.values.first;
      selectedPlanName.value = selectedPlan.name;
      selectedPlanImgUrl.value = selectedPlan.imgUrl;
      if(selectedPlan.price != null) {
        selectedPrice.value = selectedPlan.price!;
      }
    }

    isLoading.value = false;
    // SubscriptionPlanFirestore().insertSubscriptionPlans();
  }

  @override
  void onReady() async {
    update([AppPageIdConstants.accountSettings]);
  }

  Future<bool?> getSubscriptionAlert(BuildContext context, String fromRoute, {hideBasic = false}) async {
    AppUtilities.logger.d("getSubscriptionAlert");
    // selectedPrice.value = AppFlavour.getSubscriptionPrice();
    if(hideBasic) {
      subscriptionPlans.removeWhere((s, p) => p.level == SubscriptionLevel.basic);
      selectedPlan = subscriptionPlans.values.first;
      selectedPlanName.value = selectedPlan.name;
      selectedPlanImgUrl.value = selectedPlan.imgUrl;
      if(selectedPlan.price != null) {
        selectedPrice.value = selectedPlan.price!;
      }
    }
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
            CachedNetworkImage(
              imageUrl: selectedPlanImgUrl.value,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${AppTranslationConstants.subscription.tr}: ",
                  style: const TextStyle(fontSize: 15),
                ),
                DropdownButton<String>(
                  items: subscriptionPlans.values.map((SubscriptionPlan plan) {
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
              await paySubscription(fromRoute, selectedPlan);

            },
            child: Text(AppTranslationConstants.confirmAndProceed.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ]
    ).show();
  }

  Future<void> paySubscription(String fromRoute, SubscriptionPlan subscriptionPlan) async {
    AppUtilities.logger.d("Entering paySusbscription Method");

    try {
      Get.toNamed(AppRouteConstants.orderConfirmation, arguments: [selectedPlan, fromRoute]);
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
            message: 'Tu suscripción a ${('${userController.userSubscription!.level!.name}Plan').tr} fue cancelada.'
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



}
