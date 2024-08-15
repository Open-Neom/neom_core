import 'dart:core';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/data/implementations/user_controller.dart';
import '../../core/domain/model/app_profile.dart';
import '../../core/utils/app_color.dart';
import '../../core/utils/app_utilities.dart';
import '../../core/utils/constants/app_page_id_constants.dart';
import '../../core/utils/core_utilities.dart';
import '../domain/use_cases/woo_webview_service.dart';

class WooWebViewController extends GetxController implements WooWebViewService {

  final userController = Get.find<UserController>();

  AppProfile profile = AppProfile();

  WebViewController webViewController = WebViewController();
  bool isLoading = true;
  bool canPopWebView = false;

  List<String> allowedUrls = ['carrito', 'checkout'];
  bool clearCache = true;
  bool clearCookies = true;
  String url = '';

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.i("Report Controller Init");


    if(clearCache) webViewController.clearCache();
    if(clearCookies) await CoreUtilities.clearWebViewCookies();

    try {
      profile = userController.user!.profiles.first;

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        if (Get.arguments[0] is String) {
          url = Get.arguments[0];

        }
        // if (Get.arguments[1] != null && Get.arguments[1] is PurchaseOrder) {
        //   order = Get.arguments[1];
        // }
      }

      webViewController.setBackgroundColor(AppColor.main50);
      webViewController.loadRequest(Uri.parse(url));
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();

    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    webViewController.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          isLoading = true;
          update([AppPageIdConstants.wooWebView]);
        },
        onPageFinished: (String url) async {
          try {
            await webViewController.runJavaScript(
                "document.getElementById('masthead').style.display = 'none';"+
                    "document.querySelector('.cross-sells').style.display = 'none';"+
                    "document.querySelector('.actions').style.display = 'none';"+
                    "document.querySelector('.product-quantity').style.display = 'none';"
            );
            isLoading = false;
            update([AppPageIdConstants.wooWebView]);
          } catch(e) {
            AppUtilities.logger.e(e.toString());
          }

        },
        onHttpError: (HttpResponseError error) {
          AppUtilities.logger.e(error.toString());
        },
        onWebResourceError: (WebResourceError error) {
          AppUtilities.logger.e(error.toString());
        },
        onNavigationRequest: (NavigationRequest request) async {
          AppUtilities.logger.d('Navigation Request for URL: ${request.url}');
          if (request.url == url || allowedUrls.any((allowedUrl) => request.url.contains(allowedUrl))) {
            canPopWebView = false;
            update([AppPageIdConstants.wooWebView]);
            if(request.url.contains('orden-recibida')) {
              // Navigator.pop(context);
              return NavigationDecision.prevent;
            } else {
              return NavigationDecision.navigate;
            }

          } else {
            // Navigator.pop(context);
            return NavigationDecision.prevent;
          }
        },
      ),
    );

    // update([AppPageIdConstants.wooWebView]);
  }

  void setCanPopWebView(bool canPop) {
    canPopWebView = canPop;
    update([AppPageIdConstants.wooWebView]);
  }



}
