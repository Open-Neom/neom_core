import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app_flavour.dart';
import '../../domain/model/event.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_locale_constants.dart';
import '../../utils/constants/app_translation_constants.dart';


class EventTile extends StatelessWidget {

  final Event event;
  const EventTile(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 120),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColor.main75,
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.only(left: 0, right: 5, top: 10, bottom: 10),
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  kDebugMode && event.isTest ? Text('(${AppTranslationConstants.test.tr})',
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ) : const SizedBox.shrink(),
                  Text(event.name.capitalizeFirst,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  AppTheme.heightSpace5,
                  Text(event.description
                      .replaceAll(RegExp(r'\s+'), ' ') // Reemplaza saltos y espacios múltiples con un espacio
                      .trim()
                      .capitalizeFirst,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                  ),
                  AppTheme.heightSpace5,
                  Row(
                    children: <Widget>[
                      const Icon(Icons.calendar_today, size: 12),
                      AppTheme.widthSpace5,
                      Text(DateFormat.yMMMd(AppLocaleConstants.es)
                            .format(DateTime.fromMillisecondsSinceEpoch(event.eventDate)),
                        style: const TextStyle(fontSize: 12)
                      )
                    ],
                  ),
                  AppTheme.heightSpace5,
                  event.place!.name.isEmpty ? const SizedBox.shrink() :
                  Row(
                    children: <Widget>[
                      const Icon(Icons.location_on, size: 12),
                      AppTheme.widthSpace5,
                      Expanded(
                        child: Text(
                          event.place!.name,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ClipRRect(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                child: CachedNetworkImage(
                    imageUrl: event.imgUrl.isNotEmpty ? event.imgUrl
                        : AppFlavour.getNoImageUrl(),
                    // height: 120,
                    // width: 120,
                    fit: BoxFit.cover
                )
            ),
          )
        ],
      ),
    );
  }
}
