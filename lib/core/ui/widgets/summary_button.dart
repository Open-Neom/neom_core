import 'package:flutter/material.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';

class SummaryButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final bool isEnabled;
  const SummaryButton(this.text,{Key? key, this.onPressed, this.isEnabled = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColor.main50,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 20.0,
            )
          ]
      ),
      child: TextButton(
          onPressed: onPressed,
          child: SizedBox(
            width: AppTheme.fullWidth(context) / 2,
            child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  color: AppColor.white,
                  fontWeight: FontWeight.bold
              ),
            ),
          )
      ),
    );
  }
}
