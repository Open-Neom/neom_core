import '../model/report.dart';

abstract class ReportRepository {

  Future<String> insert(Report report);
  Future<bool> remove(Report report);

}
