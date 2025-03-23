import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class AppRotateAnimatedText extends StatelessWidget {

  final String text;
  final int durationMs;
  final int pauseDurationMs;
  final bool repeatForever;
  final TextStyle? textStyle;
  final bool useAnimation;
  // Constructor
  const AppRotateAnimatedText({super.key,
    required this.text,
    this.durationMs = 1600 ,
    this.pauseDurationMs = 1000,
    this.repeatForever = false,
    this.textStyle,
    this.useAnimation = true
  });

  @override
  Widget build(BuildContext context) {
    return useAnimation ? AnimatedTextKit(
      repeatForever: repeatForever,
      pause: Duration(milliseconds: durationMs),
      animatedTexts: [
        RotateAnimatedText(text,
          duration: Duration(milliseconds: pauseDurationMs),
          textStyle: textStyle,
        ),
      ],
    ) : Text(text, style: textStyle,);
  }

}
