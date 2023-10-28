import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app_flavour.dart';
import '../../domain/model/event.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_translation_constants.dart';


class EventTile extends StatelessWidget {

  final Event event;
  const EventTile(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColor.main75,
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 10),
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  kDebugMode && event.isTest ? Text(AppTranslationConstants.test.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ) : Container(),
                  Text(
                      event.name.length <= AppConstants.maxEventNameLength ? event.name.capitalizeFirst
                          : "${event.name.substring(0,AppConstants.maxEventNameLength)}...",
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  AppTheme.heightSpace5,
                  Text(event.description.length <= AppConstants.maxEventNameDescLength ? event.description.capitalizeFirst
                      : "${event.description.substring(0,30).capitalizeFirst}..."
                  ),
                  AppTheme.heightSpace5,
                  Row(
                    children: <Widget>[
                      const Icon(Icons.calendar_today, size: 12),
                      AppTheme.widthSpace5,
                      Text(DateFormat.yMMMd(AppTranslationConstants.es)
                            .format(DateTime.fromMillisecondsSinceEpoch(event.eventDate)),
                        style: const TextStyle(
                          fontSize: 12
                        )
                      )
                    ],
                  ),
                  AppTheme.heightSpace5,
                  event.place!.name.isEmpty ? Container() :
                  Row(
                    children: <Widget>[
                      const Icon(Icons.location_on, size: 12),
                      AppTheme.widthSpace5,
                      Text(event.place!.name.length <= AppConstants.maxPlaceNameLength ? event.place!.name
                          : "${event.place!.name.substring(0,AppConstants.maxPlaceNameLength)}...",
                        style: const TextStyle(
                          fontSize: 12
                        )
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: event.imgUrl.isNotEmpty ? event.imgUrl
                    : AppFlavour.getNoImageUrl(),
                height: 120,
                width: 120,
                fit: BoxFit.cover
              )
          ),
        ],
      ),
    );
  }
}
