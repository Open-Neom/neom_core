import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';

class CustomLoader {
  static CustomLoader _customLoader = CustomLoader();

  factory CustomLoader() {
      _customLoader = CustomLoader._createObject();
      return _customLoader;

  }

  CustomLoader._createObject();

  //static OverlayEntry _overlayEntry;
  late OverlayState _overlayState; //= new OverlayState();
  late OverlayEntry _overlayEntry;

  void _buildLoader() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return SizedBox(
            height: AppTheme.fullHeight(context),
            width: AppTheme.fullWidth(context),
            child: buildLoader(context));
      },
    );
  }

  void showLoader(context) {
    _overlayState = Overlay.of(context)!;
    _buildLoader();
    _overlayState.insert(_overlayEntry);
  }

  void hideLoader() {
    try {
      _overlayEntry.remove();
    } catch (e) {
      AppUtilities.logger.e("Exception:: $e");
    }
  }

  Widget buildLoader(BuildContext context, {Color? backgroundColor}) {
    backgroundColor ??= const Color(0xffa8a8a8).withOpacity(.5);
    var height = 150.0;
    return CustomScreenLoader(
      height: height,
      width: height,
      backgroundColor: backgroundColor,
    );
  }
}

class CustomScreenLoader extends StatelessWidget {
  final Color backgroundColor;
  final double height;
  final double width;
  const CustomScreenLoader({Key? key, this.backgroundColor =const Color(0xfff8f8f8), this.height = 30, this.width = 30}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Container(
        height: height,
        width: height,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(50),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Platform.isIOS
                  ? const CupertinoActivityIndicator(radius: 35,)
                  : const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
              Image.asset(
                'assets/images/icon-480.png',
                height: 30,
                width: 30,
              )
            ],
          ),
        ),
      ),
    );
  }
}
