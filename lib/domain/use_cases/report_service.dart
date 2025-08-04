
import '../../utils/enums/reference_type.dart';
import '../../utils/enums/report_type.dart';

abstract class ReportService {

  void setMessage(String text);
  void setReportType(ReportType reportType);
  Future<void> sendReport(ReferenceType referenceType, String referenceId);

  ReportType get reportType;
  bool get isButtonDisabled;

}
