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
        super.key,
        this.alignment = Alignment.center,
        this.fontSize = 14,
        this.crossAxisCount = 3,
      });

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      width: 5.0,
      height: 5.0,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(50.0)),
    );

    double gridHeight = AppTheme.fullHeight(context);
    int gridItems = genres.length;

    if(gridItems <= crossAxisCount) {
      gridHeight = (AppTheme.fullHeight(context)/15) / (crossAxisCount/gridItems).ceil();
    } else if(gridItems<10) {
      gridHeight = (AppTheme.fullHeight(context)/12) / (crossAxisCount/gridItems).ceil();
    } else if(gridItems<15) {
      gridHeight = (AppTheme.fullHeight(context)/10) / (crossAxisCount/gridItems).ceil();
    } else if(gridItems>=15) {
      gridHeight = (AppTheme.fullHeight(context)/8) / (crossAxisCount/gridItems).ceil();
      gridItems = 15;
    } else {
      gridHeight = (AppTheme.fullHeight(context)/8) / (crossAxisCount/gridItems).ceil();
    }
    return genres.isNotEmpty ? Container(
      constraints: BoxConstraints(maxHeight: AppTheme.fullHeight(context)/10,),
      child: SingleChildScrollView(
        child: Container(
          alignment: alignment,
          height: gridHeight,
          child: GridView.builder(
            itemCount: gridItems,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              String genre = genres[index];
              return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    dot,
                    Text((genre.length < AppConstants.maxGenreNameLength
                        ? genre :  genre.substring(0, AppConstants.maxGenreNameLength)).capitalize,
                      style: TextStyle(color: color, fontSize: fontSize,),
                      overflow: TextOverflow.ellipsis,
                    )
                  ]
              );
            },
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (gridItems/crossAxisCount).ceil(),
              mainAxisExtent: (AppTheme.fullWidth(context)-40)/crossAxisCount,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    ) : const SizedBox.shrink();
  }

}
