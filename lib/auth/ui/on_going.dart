
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ui/widgets/slider_model.dart';
import '../../core/utils/app_color.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/constants/app_route_constants.dart';
import '../../core/utils/constants/app_translation_constants.dart';

class OnGoing extends StatefulWidget {
  const OnGoing({super.key});

  @override
  OnGoingState createState() => OnGoingState();
}

class OnGoingState extends State<OnGoing> {
  List<SliderModel> slides = [];

  int currentState = 0;

  PageController pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    slides= SliderModel.getOnboardingSlides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.main50,
      body: PageView.builder(
        itemBuilder: (context,index){
          return SingleChildScrollView(
            child: SlideTiles(
              slides[index].imagePath,
              slides[index].msg1,
              slides[index].title,
              index,
            ),
          );
        },
        controller: pageController,
        itemCount: slides.length,
        scrollDirection: Axis.horizontal,
        onPageChanged: (val){
          currentState=val;
        },
      ),
    );
  }
}

class SlideTiles extends StatelessWidget {

  final String imagePath,text,title;
  final int current;

  const SlideTiles(this.imagePath, this.text, this.title,this.current, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: AppTheme.appBoxDecoration,
        width: AppTheme.fullWidth(context),
        height: AppTheme.fullHeight(context),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           Image.asset(imagePath,
               height: AppTheme.fullWidth(context)/2,
               width: AppTheme.fullWidth(context)/2,
               fit: BoxFit.fitWidth),
            AppTheme.heightSpace20,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for(int i=0;i<SliderModel.getOnboardingSlides().length;i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: current==i ? 20:8,
                    height: 6,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: current ==  i ? AppColor.yellow : Colors.grey[400]
                    ),
                  ),
              ],
            ),
            AppTheme.heightSpace20,
            Text(title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600
              ),
              textAlign: TextAlign.center,
            ),
            AppTheme.heightSpace10,
            Text(text,
              style: const TextStyle(fontSize: 18),textAlign: TextAlign.center,
            ),
            GestureDetector(
              onTap: () {Get.toNamed(AppRouteConstants.login);},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 30,vertical: 30),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 2,
                      color: Colors.grey,
                      offset: Offset(0,2)
                    )
                  ]
                ),
                child: Text(AppTranslationConstants.login.toUpperCase(),
                  style: const TextStyle(
                    color: AppColor.textButton,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily
                  ),
                  textAlign: TextAlign.center,
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
}
