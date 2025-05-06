import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/constants/app_locale_constants.dart';
import '../../utils/constants/app_translation_constants.dart';


class DateTimeRow extends StatelessWidget {

  ///milliSecondsSinceEpoch
  final int date;
  final bool showTime;

  const DateTimeRow({this.date = 0, this.showTime = true, super.key});

  @override
  Widget build(BuildContext context) {
    return  Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(date == 0 ? AppTranslationConstants.dateTBD.tr
              : DateFormat.yMMMd(AppLocaleConstants.es)
              .format(DateTime.fromMillisecondsSinceEpoch(date)),
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          if(showTime)
            Row(
              children: [
                const Text(" - "),
                Text(date == 0 ? AppTranslationConstants.timeTBD.tr : '${DateTime.fromMillisecondsSinceEpoch(date).hour.toString()}'
                    ':${DateTime.fromMillisecondsSinceEpoch(date).minute.toString().length == 1 ?
                "0${DateTime.fromMillisecondsSinceEpoch(date).minute}" : DateTime.fromMillisecondsSinceEpoch(date).minute.toString()}',
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
            ],)
        ]
    );
  }

}
