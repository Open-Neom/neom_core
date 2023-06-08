import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_theme.dart';

class GenresGridView extends StatelessWidget {

  final List<String> genres;
  final Color color;
  final Alignment alignment;
  final double fontSize;
  final int crossAxisCount;

  const GenresGridView(this.genres, this.color,
      {
        Key? key,
        this.alignment = Alignment.center,
        this.fontSize = 15,
        this.crossAxisCount = 3,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      width: 6.0,
      height: 6.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(50.0)),
    );

    return Container(
      alignment: alignment,
      height: AppTheme.fullHeight(context) / 12,
      width: AppTheme.fullWidth(context),
      child: GridView.builder(
        itemCount: genres.length,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Row(
              children: [
                dot,
                Text(
                  genres[index].capitalizeFirst!,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ]
          );
        },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (genres.length / crossAxisCount).ceil(),
          mainAxisExtent: AppTheme.fullWidth(context) / crossAxisCount,
        ),
      ),
    );
  }

}
