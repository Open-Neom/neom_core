import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTheme {

  static BoxDecoration appBoxDecoration = BoxDecoration(
    gradient: LinearGradient(colors: [
      AppColor.main75,
      AppColor.main50
    ],
      begin: FractionalOffset.topRight,
      end: FractionalOffset.bottomLeft, //FractionalOffset(1.0, 1.0)
    ),
  );

  static BoxDecoration appBoxDecoration75 = BoxDecoration(
    gradient: LinearGradient(colors: [
      AppColor.getMain(),
      AppColor.main75
    ],
      begin: FractionalOffset.topRight,
      end: FractionalOffset.bottomLeft, //FractionalOffset(1.0, 1.0)
    ),
  );

  static BoxDecoration appBoxDecorationFull = BoxDecoration(
    gradient: LinearGradient(colors: [
      AppColor.getMain(),
      AppColor.getMain()
    ],
      begin: FractionalOffset.topRight,
      end: FractionalOffset.bottomLeft, //FractionalOffset(1.0, 1.0)
    ),
  );

  static final appBoxDecorationBlueGrey = BoxDecoration(
    border: Border.all(color: Colors.blueGrey),
    borderRadius: BorderRadius.circular(30.0),
  );

  static const kHintTextStyle = TextStyle(
    color: Colors.white54,
    fontFamily: AppTheme.fontFamily,
  );

  static const kLabelStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: AppTheme.fontFamily,
  );

  static final kBoxDecorationStyle = BoxDecoration(
    color: AppColor.boxDecoration,
    borderRadius: BorderRadius.circular(10.0),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 6.0,
        offset: Offset(0, 2),
      ),
    ],
  );

  static const double padding25 = 25.0;
  static const double padding20 = 20.0;
  static const double padding10 = 10.0;
  static const double padding5 = 5.0;
  static const double chipsFontSize = 25;
  static final outlinedBorderChip = StadiumBorder(side: const BorderSide(color: Colors.white70).scale(0.2));
  static const primaryTitleText = TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600);
  static const primarySubtitleText = TextStyle(color: Colors.white);


  static double fullWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double fullHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static const Size appBarHeight = Size.fromHeight(50.0);

  static const double elevationFAB = 10.0;
  static const double requestIconSize = 15.0;

  static const String fontFamily = "Open-Sans";
  static const double landscapeAspectRatio = 16/9;

  static const TextStyle textStyle = TextStyle(
      fontFamily: AppTheme.fontFamily,
      color: AppColor.textColor);

  static const TextStyle messageStyle = TextStyle(fontSize: 16,
      fontFamily: AppTheme.fontFamily,
      fontWeight: FontWeight.w400);

  static const double postIconSize = 20;
  static const double postIconSizeBigger = 23;

  static final BoxDecoration boxDecoration =
    BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      color: AppColor.main25,
      border: Border.all(width: 0.5, style: BorderStyle.solid, color: Colors.white),
    );


  static final BoxDecoration selectedBoxDecoration =
     BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: AppColor.main50,
        border: Border.all(width: 0.5, style: BorderStyle.solid, color: Colors.white));

  static final BoxDecoration messageBoxDecoration = BoxDecoration(
      borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(23),
      topRight: Radius.circular(23),
      bottomRight: Radius.circular(23)),
      color: Colors.white.withOpacity(0.10)
  );

  static const SizedBox heightSpace100 = SizedBox(height: 100);
  static const SizedBox heightSpace50 = SizedBox(height: 50);
  static const SizedBox heightSpace40 = SizedBox(height: 40);
  static const SizedBox heightSpace30 = SizedBox(height: 30);
  static const SizedBox heightSpace20 = SizedBox(height: 20);
  static const SizedBox heightSpace10 = SizedBox(height: 10);
  static const SizedBox heightSpace5 = SizedBox(height: 5);

  static const SizedBox widthSpace20 = SizedBox(width: 20);
  static const SizedBox widthSpace15 = SizedBox(width: 15);
  static const SizedBox widthSpace10 = SizedBox(width: 10);
  static const SizedBox widthSpace5 = SizedBox(width: 5);

  static Color canvasColor(BuildContext context) {
    return Theme.of(context).canvasColor;
  }

  static Color canvasColor75(BuildContext context) {
    return Theme.of(context).canvasColor.withOpacity(0.75);
  }

  static Color canvasColor50(BuildContext context) {
    return Theme.of(context).canvasColor.withOpacity(0.50);
  }

  static Color canvasColor25(BuildContext context) {
    return Theme.of(context).canvasColor.withOpacity(0.25);
  }

  static Paint getTextForeGround() {
    Paint paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 1;
    paint.color = Colors.black;
    return paint;
  }

  static Color withBrightness({
    required BuildContext context,
    required Color color,
    Color? darkColor,
  }) {
    if (darkColor == null) return color;
    if (Theme.of(context).brightness == Brightness.dark) return darkColor;
    return color;
  }

  static double imageRadius = 15;

  static TextStyle defaultTitleStyle = const TextStyle(fontSize: 25, fontWeight: FontWeight.bold,);
  static TextStyle defaultSubtitle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,);

  static TextStyle bandTitleStyle = const TextStyle(fontSize: 25, fontWeight: FontWeight.bold,);
  static TextStyle eventTitleStyle = const TextStyle(fontSize: 25, fontWeight: FontWeight.bold,);
  static TextStyle requestClipTitleStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle requestsTextStyle = const TextStyle(fontSize: 15);
  static TextStyle headerTitleStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle headerSubtitleStyle = const TextStyle(fontSize: 20, color: Colors.white);
  static TextStyle eventMsgStyle = const TextStyle(fontSize: 23, fontWeight: FontWeight.bold,);



}
