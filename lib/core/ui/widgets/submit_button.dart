import 'package:flutter/material.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';

class SubmitButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final bool isEnabled;
  final bool isLoading;

  const SubmitButton(context, {Key? key,
    this.text = "", this.onPressed, this.isEnabled = true,
    this.isLoading = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppTheme.fullWidth(context) /2,
      height: AppTheme.fullHeight(context) /15,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppColor.bondiBlue75,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: isEnabled ? onPressed : ()=>{},
        child: isLoading ? const Center(child: CircularProgressIndicator())
            : Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15
          ),
        ),
      ),
    );
  }
}
