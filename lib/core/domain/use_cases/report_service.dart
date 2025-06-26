
import '../../utils/enums/reference_type.dart';

abstract class ReportService {

  void setMessage(String text);
  void setReportType(String reportType);
  Future<void> sendReport(ReferenceType referenceType, String referenceId);

}
