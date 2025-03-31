import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/firestore/nupale_session_firestore.dart';
import '../../../domain/model/nupale/nupale_session.dart';
import '../../../utils/app_theme.dart';
import '../../widgets/appbar_child.dart';
import 'nupale_line_chart.dart';

class NupaleItemStatisticsPage extends StatelessWidget {
  final String itemId;
  final String itemName;

  const NupaleItemStatisticsPage({super.key, required this.itemId, required this.itemName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarChild(title: itemName),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<NupaleSession>>(
          future: getNupaleSessionsByItem(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar los datos'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay sesiones para este libro'));
            } else {
              final sessions = snapshot.data!;

              final totalPages = sessions.fold(0, (prev, s) => prev + s.nupale);
              final totalFreemium = sessions.where((s) => s.isFreemium).length;
              final totalInternal = sessions.where((s) => s.isInternalArtist).length;
              final totalTest = sessions.where((s) => s.isTest).length;
              final readers = sessions.map((s) => s.readerId).toSet();

              return Column(children: [
                NupaleLineChart(sessions: sessions),
                ListView(
                  children: [
                    Text('Total páginas leídas: $totalPages', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text('Total lectores: ${readers.length}'),
                    Text('Freemium: $totalFreemium'),
                    Text('Internal Artists: $totalInternal'),
                    Text('Tests: $totalTest'),
                    const SizedBox(height: 20),
                    const Text('Páginas leídas por usuario:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...sessions.map((session) => ListTile(
                      title: Text(session.readerId),
                      subtitle: Text('${session.nupale} páginas leídas'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (session.isFreemium) const Text('Freemium', style: TextStyle(color: Colors.orange)),
                          if (session.isInternalArtist) const Text('Internal', style: TextStyle(color: Colors.blue)),
                          if (session.isTest) const Text('Test', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    )).toList()
                  ],
                )
              ],);
            }
          },
        ),
      ),
    );
  }

  Future<List<NupaleSession>> getNupaleSessionsByItem() async {
    final nupaleSessions = await NupaleSessionFirestore().fetchAll();
    return nupaleSessions.values.where((s) => s.itemId == itemId).toList();
  }
}