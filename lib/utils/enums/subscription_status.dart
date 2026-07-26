enum SubscriptionStatus {
  active,        // Subscription is currently active
  inactive,      // Subscription is inactive
  cancelled,     // Subscription has been cancelled
  paused,        // Subscription is temporarily paused
  pending,       // Subscription is pending activation
  expired,       // Subscription has expired
  trial,         // Trial period of the subscription
  renewing,      // Subscription is in the process of renewing
  suspended,     // Subscription suspended due to overdue payment
  pastDue,       // (kimi, 2026-07-23) Pago fallido, en periodo de gracia
}
