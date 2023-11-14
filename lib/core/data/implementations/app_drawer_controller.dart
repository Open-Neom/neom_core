import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../neom_commons.dart';

//TODO IS MISSING INTERFACE AS SERVICE
class AppDrawerController extends GetxController {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppUser user = AppUser();

  final Rx<AppProfile> _profile = AppProfile().obs;
  AppProfile get appProfile => _profile.value;
  set appProfile(AppProfile profile) => _profile.value = profile;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  @override
  void onInit() async {
    super.onInit();
    logger.i("SideBar Controller Init");
    user = userController.user!;
    appProfile = userController.profile;
  }

  void updateProfile(AppProfile profile) {
    appProfile = profile;
    update([AppPageIdConstants.appDrawer]);
  }

  Future<void> selectProfileModal(BuildContext treeContext) async {

    try {
      await userController.getProfiles();
      await showModalBottomSheet(
          elevation: 0,
          backgroundColor: AppTheme.canvasColor25(treeContext),
          context: treeContext,
          builder: (BuildContext context) {
            return SingleChildScrollView(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                      color: AppColor.main95,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))
                  ),
                  child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      separatorBuilder:  (context, index) => const Divider(),
                      itemCount: user.profiles.length,
                      itemBuilder: (ctx, index) {
                        AppProfile profile = user.profiles.elementAt(index);
                        return ListTile(
                          leading: IconButton(
                            icon: CircleAvatar(
                                maxRadius: 60,
                                backgroundImage: CachedNetworkImageProvider(
                                    profile.photoUrl.isNotEmpty
                                        ? profile.photoUrl
                                        : AppFlavour.getNoImageUrl()
                                )
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              if(appProfile.id != profile.id) {
                                Navigator.pop(treeContext);
                                await userController.changeProfile(profile);
                              }
                            },
                          ),
                          trailing: Icon(
                              appProfile.id == profile.id
                                  ? FontAwesomeIcons.circleDot
                                  : Icons.circle_outlined,
                              size: 30
                          ),
                          title: Text(profile.name,
                            style: const TextStyle(fontSize: 18),
                          ),
                          subtitle: Text("${profile.type.name.tr.capitalize} - ${profile.mainFeature.tr.capitalize}"),
                          onTap: () async {
                            Navigator.pop(context);
                            if(appProfile.id != profile.id) {
                              Navigator.pop(treeContext);
                              await userController.changeProfile(profile);
                            }
                          },
                        );
                      }
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  color: AppColor.main95,                  
                  child: ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(30)),
                        color: Colors.teal[100],
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 15,),
                    title: const Text("Crear perfil adicional",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    subtitle: const Text("Agrega un perfil adicional para manejar distintas cuentas."),
                    onTap: () {
                      Navigator.pop(treeContext);
                      Get.toNamed(AppRouteConstants.introProfile);
                    },
                  ),
                ),
              ],
            ));
          });

      isButtonDisabled = false;
    } catch(e) {
      logger.e(e.toString());
    }

    update();
  }

}
