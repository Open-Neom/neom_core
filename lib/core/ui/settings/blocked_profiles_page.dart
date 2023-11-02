// ignore_for_file: use_build_context_synchronously
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_profile/mates/ui/mate_details/mate_details_controller.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../data/implementations/mate_controller.dart';
import '../../domain/model/app_profile.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/core_utilities.dart';
import '../widgets/appbar_child.dart';

class BlockedProfilesPage extends StatelessWidget {
  const BlockedProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateController>(
      id: AppPageIdConstants.following,
      init: MateController(),
      builder: (_) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarChild(title: AppTranslationConstants.blockedProfiles.tr)
      ),
      backgroundColor: AppColor.main50,
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: _.mates.isEmpty ?
          const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _.mates.length,
          itemBuilder: (context, index) {
            AppProfile mate = _.mates.values.elementAt(index);
            return mate.name.isNotEmpty ? GestureDetector(
              child: ListTile(
                onTap: () {
                  MateDetailsController itemmateDetailsController = Get.put(MateDetailsController());
                  if(_.userController.profile.blockTo!.contains(mate.id)) {
                    Alert(
                        context: context,
                        style: AlertStyle(
                          backgroundColor: AppColor.main50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: AppTranslationConstants.unblockProfile.tr,
                        content: Column(
                          children: [
                            Text(AppTranslationConstants.unblockProfileMsg.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        buttons: [
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              Get.back();
                            },
                            child: Text(AppTranslationConstants.goBack.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          DialogButton(
                            color: AppColor.bondiBlue75,
                            onPressed: () async {
                              if(!itemmateDetailsController.isButtonDisabled) {
                                await itemmateDetailsController.unblockProfile(mate);
                                AppUtilities.showAlert(context, title: AppTranslationConstants.unblockProfile.tr, message: AppTranslationConstants.unblockedProfileMsg.tr);
                              }
                            },
                            child: Text(AppTranslationConstants.toUnblock.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                          )
                        ]
                    ).show();
                  } else {
                    itemmateDetailsController.isLoading = false;
                    itemmateDetailsController.mate = mate;
                    _.getMateDetails(mate);
                  }

                },
                leading: Hero(
                  tag: mate.photoUrl,
                  child: FutureBuilder<CachedNetworkImageProvider>(
                    future: CoreUtilities.handleCachedImageProvider(mate.photoUrl),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return CircleAvatar(backgroundImage: snapshot.data);
                      } else {
                        return const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: CircularProgressIndicator()
                        );
                      }
                    },
                  )
                ),
                title: Text(mate.name),
                subtitle: Row(
                  children: [
                    Text(mate.favoriteItems?.length.toString() ?? ""),
                    const Icon(Icons.book, color: Colors.blueGrey, size: 20,),
                    Text(mate.mainFeature.tr.capitalize),
                  ]),
                ),
              onLongPress: () => {},
            ) : Container();
          },
        ),
      )
    ));
  }
}
