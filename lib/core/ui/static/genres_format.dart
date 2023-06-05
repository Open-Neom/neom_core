import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_theme.dart';

class GenresFormat extends StatefulWidget {

  final List<String> genres;
  final Color color;
  final Alignment alignment;
  final double fontSize;

  const GenresFormat(this.genres, this.color,
      {
        Key? key,
        this.alignment = Alignment.center,
        this.fontSize = 15
      }) : super(key: key);

  @override
  GenresFormatState createState() => GenresFormatState();
}

class GenresFormatState extends State<GenresFormat> {

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      width: 6.0,
      height: 6.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
          color: widget.color, borderRadius: BorderRadius.circular(50.0)),
    );

    return Container(
      alignment: widget.alignment,
      height: AppTheme.fullHeight(context)/12,
      width: AppTheme.fullWidth(context),
      child: GridView.builder(
        itemCount: widget.genres.length,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Row(
              children: [
                dot,
                Text(
                  widget.genres[index].capitalizeFirst!,
                  style: TextStyle(
                      color: widget.color,
                      fontSize: widget.fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ]
          );
          },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (widget.genres.length / 4).ceil(),
            mainAxisExtent: AppTheme.fullWidth(context)*0.4,
        ),
      ),
    );
  }
}
