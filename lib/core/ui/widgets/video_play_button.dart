import 'package:flutter/material.dart';


class VideoPlayButton extends StatelessWidget {

  final bool isPlaying;
  final Function? controllerFunction;

  const VideoPlayButton({this.isPlaying = false, this.controllerFunction, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  const Color(0x36FFFFFF).withOpacity(0.1),
                  const Color(0x0FFFFFFF).withOpacity(0.1)
                ],
                begin: FractionalOffset.topLeft,
                end: FractionalOffset.bottomRight
            ),
            borderRadius: BorderRadius.circular(50)
        ),
        child: IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,),
          iconSize: 75,
          color: Colors.white54,
          onPressed: () {
            if(controllerFunction != null) {
              controllerFunction!();
            }
          },
        ),
      ),
    );
  }

}
