import 'package:flutter/material.dart';

class PositionBackButton extends StatelessWidget {
  const PositionBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 30.0, left: 10.0,
      child: BackButton(color: Colors.white),
    );
  }
}
