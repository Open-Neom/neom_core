import 'package:flutter/material.dart';
import '../../utils/app_color.dart';

class StarRating extends StatefulWidget {

  final double rating;

  const StarRating(this.rating, {Key? key}) : super(key: key);

  @override
  StarRatingState createState() => StarRatingState();
}

class StarRatingState extends State<StarRating> {
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
        if(index < (widget.rating / 2).round()){
          return star(true);
        }
        else
          {
            return star(false);
          }
      }),
    );
  }
}
