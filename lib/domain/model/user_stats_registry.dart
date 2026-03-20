/// Singleton registry where modules dump their user stats as key-value pairs.
///
/// This allows neom_ia (Itzli) to read stats from neom_nupale and neom_casete
/// without creating direct dependencies between modules.
///
/// Usage:
/// - Nupale/Casete controllers call [register] after loading sessions.
/// - ItzliUserStats reads via [getAll] when the user asks about their stats.
class UserStatsRegistry {
  UserStatsRegistry._();

  static final UserStatsRegistry instance = UserStatsRegistry._();

  /// Module name → stats map (display label → value string).
  final Map<String, Map<String, String>> _stats = {};

  /// Register stats for a module (replaces previous stats for that module).
  void register(String module, Map<String, String> stats) {
    _stats[module] = Map.unmodifiable(stats);
  }

  /// Get stats for a specific module, or null if not registered.
  Map<String, String>? getModule(String module) => _stats[module];

  /// Get all registered stats across all modules.
  Map<String, Map<String, String>> getAll() => Map.unmodifiable(_stats);

  /// Whether any stats have been registered.
  bool get hasStats => _stats.isNotEmpty;

  /// Clear all registered stats (e.g., on logout).
  void clear() => _stats.clear();
}
