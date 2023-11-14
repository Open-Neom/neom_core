import 'package:flutter/material.dart';
import '../../utils/app_color.dart';

class StarRating extends StatelessWidget {

  final double rating;
  const StarRating(this.rating, {super.key});

  @override
  Widget build(BuildContext context) {

    Widget star(bool fill){
      return Icon(
        Icons.star,
        size: 15.0,
        color: fill ? AppColor.yellow : Colors.grey,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return index < (rating/2).round() ?
          star(true) : star(false);
      }),
    );
  }
}
