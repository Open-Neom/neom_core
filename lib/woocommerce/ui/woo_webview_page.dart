import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/ui/widgets/app_circular_progress_indicator.dart';
import '../../core/utils/app_color.dart';
import '../../core/utils/constants/app_page_id_constants.dart';
import 'woo_webview_controller.dart';

class WooWebViewPage extends StatelessWidget {

  const WooWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WooWebViewController>(
      id: AppPageIdConstants.wooWebView,
      init: WooWebViewController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: SafeArea(
          child: PopScope(
            canPop: _.canPopWebView,
            onPopInvoked: (didPop) async {
              if (await _.webViewController.canGoBack()) {
                await _.webViewController.goBack();
              } else {
                _.setCanPopWebView(true);
              }
            },
            child: _.isLoading ? AppCircularProgressIndicator() : WebViewWidget(
              controller: _.webViewController,
            ),
          ),
        ),
      )
    );
  }

}
