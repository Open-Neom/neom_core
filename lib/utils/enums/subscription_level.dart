/// Generic subscription tiers for the Open Neom ecosystem.
///
/// Numeric values support `>=` comparisons in usage/tier logic.
/// Each app translates these to its own branding via app_translations.
enum SubscriptionLevel {
  freemium(0),
  freeMonth(1),
  basic(2),
  plus(3),
  family(4),
  creator(5),
  ambassador(6),
  artist(7),
  professional(8),
  corporate(9),
  premium(10),
  platinum(11),
  lifetime(12);

  final int value;
  const SubscriptionLevel(this.value);
}

