/// ERP-level privileges for financial intelligence access.
/// These are assigned independently of UserRole to allow
/// granular control over who can view/manage financial data.
enum ErpPrivilege {
  viewFinancialKpis,
  manageSubscriptionStatus,
  viewPaymentHistory,
  exportRevenueForecast,
}
