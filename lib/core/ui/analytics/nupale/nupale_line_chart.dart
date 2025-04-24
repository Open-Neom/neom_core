// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../../../domain/model/nupale/nupale_session.dart';
//
// class NupaleLineChart extends StatelessWidget {
//   final List<NupaleSession> sessions;
//
//   const NupaleLineChart({super.key, required this.sessions});
//
//   @override
//   Widget build(BuildContext context) {
//     if (sessions.isEmpty) {
//       return const Text('No hay datos para graficar');
//     }
//
//     // Agrupar por fecha (yyyy-MM-dd)
//     final Map<DateTime, int> nupaleByDay = {};
//     for (var session in sessions) {
//       final date = DateTime.fromMillisecondsSinceEpoch(session.createdTime);
//       final cleanDate = DateTime(date.year, date.month, date.day);
//       nupaleByDay[cleanDate] = (nupaleByDay[cleanDate] ?? 0) + session.nupale;
//     }
//
//     final sortedDates = nupaleByDay.keys.toList()..sort();
//     final spots = sortedDates.asMap().entries.map((entry) {
//       final index = entry.key;
//       final date = entry.value;
//       return FlSpot(index.toDouble(), nupaleByDay[date]!.toDouble());
//     }).toList();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text('Tendencia de lectura en el tiempo',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 10),
//         SizedBox(
//           height: 200,
//           child: LineChart(
//             LineChartData(
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: spots,
//                   isCurved: true,
//                   dotData: FlDotData(show: true),
//                 ),
//               ],
//               titlesData: FlTitlesData(
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     interval: 1,
//                     getTitlesWidget: (value, meta) {
//                       final index = value.toInt();
//                       if (index >= sortedDates.length) return const SizedBox();
//                       final d = sortedDates[index];
//                       return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10));
//                     },
//                   ),
//                 ),
//                 leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
//               ),
//               gridData: FlGridData(show: true),
//               borderData: FlBorderData(show: true),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
