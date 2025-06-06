import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/firestore/app_analytics_firestore.dart';
import '../../domain/model/analytics/user_locations.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../widgets/app_circular_progress_indicator.dart';
import '../widgets/appbar_child.dart';
import 'charts/yearly_line_chart.dart';

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
        child: SingleChildScrollView(
          child: FutureBuilder<List<UserLocations>>(
            future: AppAnalyticsFirestore().getUserLocations(), // Replace with your own function to fetch userLocations asynchronously
            builder: (context, snapshot) {
              AppUtilities.logger.d("AnalyticsPage: FutureBuilder snapshot: ${snapshot.connectionState} - ${snapshot.data?.length ?? 0}");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppCircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading userLocations'),
                );
              } else {

                List<UserLocations> userLocations = [];
                Map<String,int> dateData = {};

                List<MapEntry<String, int>> sortedEntries = [];
                if(snapshot.data != null) {
                  userLocations = snapshot.data!;
                  userLocations.sort((a, b) => parseDateId(b.dateId).compareTo(parseDateId(a.dateId)));
                  dateData = userLocations.first.locationCounts ?? {};

                  sortedEntries = dateData.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                }

                Map<int, int> monthlyValues = {};

                for (UserLocations ul in userLocations) {
                  // Convertir el dateId a DateTime para extraer el mes.
                  DateTime? date = parseDateId(ul.dateId);
                  int month = date.month;
                  // Acumular totalUsers para cada mes.
                  if(monthlyValues[month] == null || (monthlyValues[month] ?? 0) < ul.totalUsers) {
                    monthlyValues[month] = ul.totalUsers;
                  }

                }

                return Column(
                  children: [
                    YearlyLineChart(monthlyValues: monthlyValues, yTitle: AppTranslationConstants.users.tr,),
                    AppTheme.heightSpace5,
                    Text('${monthlyValues[DateTime.now().month]} ${AppTranslationConstants.users.tr.capitalize}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20
                      ),
                    ),
                    AppTheme.heightSpace5,
                    DataTable(
                      columns: [
                        DataColumn(label: Text(AppTranslationConstants.location.tr,style: const TextStyle(fontWeight: FontWeight.bold),)),
                        DataColumn(label: Text(AppTranslationConstants.qty.tr,style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: sortedEntries.map((item) => DataRow(
                        cells: [
                          DataCell(Text(item.key.tr)),
                          DataCell(Text(item.value.toString()),),
                        ],
                      )).toList(),
                    )
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  DateTime parseDateId(String dateId) {
    if(dateId.isEmpty) return DateTime(0);

    final month = int.parse(dateId.substring(0, 2));
    final day = int.parse(dateId.substring(2, 4));
    final year = int.parse(dateId.substring(4));
    return DateTime(year, month, day);
  }

}
