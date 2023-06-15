import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/firestore/app_analytics_firestore.dart';
import '../../domain/model/app_analytics.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../widgets/appbar_child.dart';

class AnalyticsPage extends StatefulWidget {

  const AnalyticsPage({super.key});

  @override
  AnalyticsPageState createState() => AnalyticsPageState();

}

class AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarChild(title: AppTranslationConstants.analytics.tr),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        height: AppTheme.fullHeight(context),
        child: SingleChildScrollView(child: FutureBuilder<List<AppAnalytics>>(
        future: AppAnalyticsFirestore().getAnalytics(), // Replace with your own function to fetch data asynchronously
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading data'),
            );
          } else {

            List<AppAnalytics> data = [];
            if(snapshot.data != null) {
              data = snapshot.data!;
              data.sort((a, b) => b.qty.compareTo(a.qty));
            }
            return DataTable(
              columns: [
                DataColumn(label: Text(AppTranslationConstants.location.tr,style: const TextStyle(fontWeight: FontWeight.bold),)),
                DataColumn(label: Text(AppTranslationConstants.qty.tr,style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: data.map((item) => DataRow(
                cells: [
                  DataCell(Text(item.location.tr)),
                  DataCell(Text(item.qty.toString()),),
                ],
              )).toList(),
            );
          }
        },
      ),),
      ),
    );
  }

}
