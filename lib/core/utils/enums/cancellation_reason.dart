enum CancellationReason {
  userCancelled,        // User voluntarily cancelled
  paymentFailed,        // Subscription cancelled due to payment failure
  expired,              // Subscription expired without renewal
  termsViolation,       // Cancelled due to a violation of terms
  switchingPlans,       // User is switching to a different plan
  serviceDiscontinued,  // Service or product is no longer available
  other,                // Other reasons
}
