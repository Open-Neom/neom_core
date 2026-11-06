/// Cross-module contract for EMXI Fondeos (`neom_founding`).
///
/// Allows modules such as `neom_commerce` (`/cotizacion`) and `neom_timeline`
/// to pre-populate the campaign creation wizard or navigate to campaigns
/// without creating circular package dependencies.
abstract class FoundingService {
  Future<void> openExplorer();

  Future<void> openCampaignDetail(
    String slugOrId, {
    String? secretToken,
    String? referralTag,
  });

  Future<void> openWizardFromQuotation({
    required int pages,
    required int copies,
    required double quotedCostMxn,
    required double unitPriceMxn,
    required String formatSummary,
    required int estimatedDeliveryDays,
    Map<String, double> budgetBreakdown = const {},
  });
}
