import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/firestore/nupale_session_firestore.dart';
import '../../../data/implementations/user_controller.dart';
import '../../../domain/model/nupale/nupale_session.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants/app_translation_constants.dart';
import '../../../domain/model/app_user.dart';
import '../../../data/firestore/user_firestore.dart';
import '../../widgets/appbar_child.dart';
import 'nupale_item_stats_page.dart';

class NupaleStatisticsRootPage extends StatefulWidget {
  const NupaleStatisticsRootPage({super.key});

  @override
  State<NupaleStatisticsRootPage> createState() => _NupaleStatisticsRootPageState();
}

class _NupaleStatisticsRootPageState extends State<NupaleStatisticsRootPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    NupaleTopBooksPage(),
    NupaleDailyLineChartPage(),
    NupaleSummaryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarChild(title: AppTranslationConstants.analytics.tr),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Top Libros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Por Día',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Resumen',
          ),
        ],
      ),
    );
  }
}

class NupaleTopBooksPage extends StatelessWidget {
  const NupaleTopBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NupaleSession>>(
      future: NupaleSessionFirestore().fetchAll().then((m) => m.values.toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final sessions = snapshot.data!;
        final groupedByBook = <NupaleSession, int>{};

        for (var session in sessions) {
          groupedByBook[session] =
              (groupedByBook[session] ?? 0) + session.nupale;
        }

        final top10 = groupedByBook.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Top 10 Libros más Leídos', style: TextStyle(fontWeight: FontWeight.bold)),
            ...top10.take(10).map((e) => InkWell(
              onTap: () => Get.to(() => NupaleItemStatisticsPage(itemId: e.key.itemId, itemName: e.key.itemName)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• ${e.key.itemName}: ${e.value} páginas'),
              ),
            )),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: top10.take(10).toList().asMap().entries.map((entry) =>
                      BarChartGroupData(x: entry.key, barRods: [
                        BarChartRodData(toY: entry.value.value.toDouble(), width: 14)
                      ])).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        return Text(top10[index].key.itemName, style: const TextStyle(fontSize: 8));
                      },
                    )),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NupaleDailyLineChartPage extends StatelessWidget {
  const NupaleDailyLineChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = Get.find<UserController>().user.email;
    final now = DateTime.now();

    return FutureBuilder<List<NupaleSession>>(
      future: NupaleSessionFirestore().fetchAll().then((m) => m.values.toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final sessions = snapshot.data!;
        final byDay = <int, int>{};

        for (var session in sessions) {
          if (session.ownerId == userEmail) {
            final date = DateTime.fromMillisecondsSinceEpoch(session.createdTime);
            if (date.month == now.month && date.year == now.year) {
              final day = date.day;
              byDay[day] = (byDay[day] ?? 0) + session.nupale;
            }
          }
        }

        final totalRead = byDay.values.fold(0, (a, b) => a + b);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Total páginas leídas este mes: $totalRead',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: byDay.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                        isCurved: true,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class NupaleSummaryPage extends StatelessWidget {
  const NupaleSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NupaleSession>>(
      future: NupaleSessionFirestore().fetchAll().then((m) => m.values.toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final sessions = snapshot.data!;
        final totalSessions = sessions.length;
        final totalNupale = sessions.fold(0, (a, s) => a + s.nupale);
        final avgPerSession = totalSessions > 0 ? totalNupale / totalSessions : 0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total sesiones: $totalSessions'),
              Text('Total páginas leídas: $totalNupale'),
              Text('Promedio por sesión: ${avgPerSession.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              const Text('Más estadísticas próximamente...'),
            ],
          ),
        );
      },
    );
  }
}
