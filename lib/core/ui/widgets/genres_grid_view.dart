import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants/app_constants.dart';

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

    double gridHeight = AppTheme.fullHeight(context);

    if(genres.length <= crossAxisCount) {
      gridHeight = (AppTheme.fullHeight(context) / 8) / (crossAxisCount/genres.length).ceil();
    } else if(genres.length<15) {
      gridHeight = (AppTheme.fullHeight(context) / 12) / (crossAxisCount/genres.length).ceil();
    } else if(genres.length>=15) {
      gridHeight = (AppTheme.fullHeight(context) / 3) / (crossAxisCount/genres.length).ceil();
    } else {
      gridHeight = (AppTheme.fullHeight(context) / 5) / (crossAxisCount/genres.length).ceil();
    }
    return genres.isNotEmpty ? SizedBox(
      height: AppTheme.fullHeight(context) / 10,
      width: AppTheme.fullWidth(context),
      child: SingleChildScrollView(
        child: Container(
          alignment: alignment,
          height: gridHeight,
          width: AppTheme.fullWidth(context),
          child: GridView.builder(
            itemCount: genres.length,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              String genre = genres[index];
              return Row(
                  children: [
                    dot,
                    Text(
                        (genre.length < AppConstants.maxGenreNameLength
                          ? genre :  genre.substring(0, AppConstants.maxGenreNameLength)).capitalize!,
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
        ),
      ),
    ) : Container();
  }

}
