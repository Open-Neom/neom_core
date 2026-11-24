/// Lightweight cross-module summary of a creator's crowdfunding campaign,
/// allowing profile surfaces (`neom_profile`, `neom_mates`) to render live
/// progress without depending on `neom_founding`.
class FoundingProfileCampaignSummary {
  final String id;
  final String slug;
  final String title;
  final String statusName;
  final String statusLabelEs;
  final double goalAmount;
  final double currentAmount;
  final int backerCount;
  final int daysRemaining;
  final String assignedResponsibleName;
  final String staffStatusNote;

  const FoundingProfileCampaignSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.statusName,
    required this.statusLabelEs,
    required this.goalAmount,
    required this.currentAmount,
    required this.backerCount,
    required this.daysRemaining,
    this.assignedResponsibleName = '',
    this.staffStatusNote = '',
  });

  double get progressRatio =>
      goalAmount <= 0 ? 0.0 : (currentAmount / goalAmount).clamp(0.0, 1.0);

  int get progressPercent =>
      goalAmount <= 0 ? 0 : ((currentAmount / goalAmount) * 100).round();

  double get fiftyReadersRatio => (backerCount / 50.0).clamp(0.0, 1.0);
}

/// Cross-module contract for EMXI Fondeos (`neom_founding`).
///
/// Allows modules such as `neom_commerce` (`/cotizacion`), `neom_profile`,
/// `neom_mates`, and `neom_timeline` to pre-populate the campaign creation
/// wizard, display live campaign progress on profiles, or navigate to
/// campaigns without creating circular package dependencies.
abstract class FoundingService {
  Future<void> openExplorer();

  Future<void> openCampaignDetail(
    String slugOrId, {
    String? secretToken,
    String? referralTag,
  });

  Future<void> openCreatorDashboard({String? campaignId});

  Future<List<FoundingProfileCampaignSummary>> getProfileCampaignSummaries({
    required String ownerUid,
    bool includePrivate = false,
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
