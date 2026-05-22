import 'package:sint/sint.dart';

import '../app_config.dart';
import '../data/implementations/user_controller.dart';
import 'enums/subscription_level.dart';

/// # AppGates · Unified launch-gate helper
///
/// Combines the two layers of feature gating into a single, intention-revealing
/// API so the rest of the codebase never has to remember which global flag to
/// combine with which subscription check.
///
/// ## Capas
///
/// ```
/// Capa 1 — Global flags       (AppConfig.instance.*)
///   • showBetaFeatures        : master kill-switch for beta (false in launch)
///   • hasEarlyAccess          : master kill-switch for early access
///   • isAdminMode             : admin bypass
///
/// Capa 2 — Per-user tier      (SubscriptionLevel on UserController)
///   • premium+                : beta
///   • platinum+               : early access
/// ```
///
/// Capa 3 (flavour) stays at the call site via `AppFlavour.showX()` because
/// `AppFlavour` lives in `neom_commons` and we can't import it from `neom_core`
/// without creating a circular dependency.
///
/// ## Uso
///
/// ```dart
/// // Antes:
/// if (AppFlavour.showVst() && AppConfig.instance.showBetaFeatures) { ... }
///
/// // Ahora:
/// if (AppFlavour.showVst() && AppGates.canUseBeta()) { ... }
///
/// // Saia launch gates:
/// if (AppGates.canUseSaiaMemory())        { /* show memory UI */ }
/// if (AppGates.canUseSaiaMultiProvider()) { /* show provider picker */ }
/// if (AppGates.canUseSaiaOffline())       { /* show Ollama card */ }
/// ```
class AppGates {
  AppGates._();

  // ====================================================================
  // Capa 1 · Global flags (AppConfig)
  // ====================================================================

  /// Master global switch for beta features. `false` during Itzli launch.
  static bool get showBeta => AppConfig.instance.showBetaFeatures;

  /// Master global switch for early access features. `true` during launch.
  /// Acts as an emergency kill-switch: if something goes wrong post-launch,
  /// flipping this to `false` hides every early access feature instantly.
  static bool get earlyAccessEnabled => AppConfig.instance.hasEarlyAccess;

  /// Admin override. When `true`, all gates return `true` regardless of
  /// global flags or subscription level.
  static bool get isAdmin => AppConfig.instance.isAdminMode;

  // ====================================================================
  // Capa 2 · Per-user subscription level
  // ====================================================================

  /// Resolves the current user's [SubscriptionLevel] safely.
  ///
  /// Falls back to [SubscriptionLevel.freemium] in any of these cases:
  ///   • [UserController] is not yet registered (startup, splash).
  ///   • Tests run without a fake user controller.
  ///   • Guest mode before login.
  ///   • Any transient error reading the level.
  static SubscriptionLevel currentLevel() {
    if (!Sint.isRegistered<UserController>()) {
      return SubscriptionLevel.freemium;
    }
    try {
      return Sint.find<UserController>().subscriptionLevel;
    } catch (_) {
      return SubscriptionLevel.freemium;
    }
  }

  /// True iff the given (or current) level is premium or higher.
  /// Premium is the baseline for beta features.
  static bool isPremiumOrAbove([SubscriptionLevel? level]) {
    final l = level ?? currentLevel();
    return l.index >= SubscriptionLevel.premium.index;
  }

  /// True iff the given (or current) level is platinum or higher.
  /// Platinum is the baseline for early access.
  ///
  /// `lifetime` (index 12) naturally passes this check.
  static bool isPlatinumOrAbove([SubscriptionLevel? level]) {
    final l = level ?? currentLevel();
    return l.index >= SubscriptionLevel.platinum.index;
  }

  // ====================================================================
  // Capas combinadas · Generic gates
  // ====================================================================

  /// Canonical check for beta features. Replaces raw
  /// `AppConfig.instance.showBetaFeatures` checks across the app.
  ///
  /// Resolution order:
  ///   1. Admin bypass.
  ///   2. Global `showBetaFeatures` master switch (must be on).
  ///   3. User subscription >= premium.
  static bool canUseBeta() {
    if (isAdmin) return true;
    if (!showBeta) return false;
    return isPremiumOrAbove();
  }

  /// Hidden-beta gate for features that must stay invisible to the general
  /// public during the Itzli launch but remain accessible to admins and to
  /// paying users that help us dogfood them (InterComm, Booking, VST, DAW).
  ///
  /// Unlike [canUseBeta], the three conditions are **OR-ed**: any single one
  /// grants access. This lets us ship with `showBetaFeatures = false` while
  /// still letting premium+ members try in-progress features.
  ///
  /// Resolution order (any match wins):
  ///   1. Global `showBetaFeatures` master switch is on, OR
  ///   2. Admin bypass, OR
  ///   3. User subscription >= premium.
  static bool canUseHiddenBeta() {
    if (showBeta) return true;
    if (isAdmin) return true;
    return isPremiumOrAbove();
  }

  /// Canonical check for early access features.
  ///
  /// Resolution order:
  ///   1. Admin bypass.
  ///   2. Global `hasEarlyAccess` master switch (must be on).
  ///   3. User subscription >= platinum.
  static bool canUseEarlyAccess() {
    if (isAdmin) return true;
    if (!earlyAccessEnabled) return false;
    return isPlatinumOrAbove();
  }

  // ====================================================================
  // Saia · Semantic aliases
  // ====================================================================
  //
  // These wrap the generic gates with intention-revealing names so the UI
  // reads as product features, not as plumbing. If the tier for any of these
  // changes later, the change is local to this file — no grep-and-replace.
  //
  // "Saia" is used as a neutral product-agnostic prefix so these helpers can
  // be reused across flavours without tying the API to any single brand.

  /// Saia long-term memory: dreaming scorer, consolidation, personal context.
  static bool canUseSaiaMemory() => canUseEarlyAccess();

  /// Saia multi-provider routing (Claude + GPT + Gemini + Mistral).
  static bool canUseSaiaMultiProvider() => canUseEarlyAccess();

  /// Saia advanced tool calling: subagents, MCP, code execution, RAG.
  static bool canUseSaiaAdvancedTools() => canUseEarlyAccess();

  /// Saia offline mode with local Ollama models.
  ///
  /// **Intentionally not gated by subscription tier.** Offline sovereignty
  /// is a core product differentiator and should be available to everyone.
  /// Only the global kill-switch and admin bypass apply.
  static bool canUseSaiaOffline() {
    if (isAdmin) return true;
    return earlyAccessEnabled;
  }

  /// Saia launch master check. Returns `true` if Saia as a product is
  /// active at all (regardless of per-feature tiers). Useful for the main
  /// entry point of the Saia experience in the drawer/sidebar.
  static bool isSaiaLaunchActive() {
    if (isAdmin) return true;
    return earlyAccessEnabled;
  }

  /// Saia benchmark runner (`neom_ia_bench`).
  ///
  /// **Admin-only for now.** The bench is wired behind this gate so the
  /// product owner can dogfood it personally against real providers
  /// (Gemini, Claude, GPT, Ollama) before opening it to paying tiers.
  ///
  /// To open it up later without touching call sites, extend the body:
  /// ```dart
  /// static bool canUseSaiaBench() {
  ///   if (isAdmin) return true;
  ///   return isPlatinumOrAbove(); // ← step 1: platinum+
  ///   // return isPremiumOrAbove(); // ← step 2: premium+
  ///   // return true; // ← step 3: public
  /// }
  /// ```
  static bool canUseSaiaBench() {
    return isAdmin;
  }
}
