/// Global, dependency-free registry signaling that the current screen shows a
/// bottom-right Floating Action Button (or similar corner action).
///
/// Floating overlays that live in the same corner — e.g. the Itzli chat
/// bubble — read this to **step aside** and avoid covering the page's primary
/// action button.
///
/// Uses a counter (push/pop) so stacked/nested pages with FABs behave
/// correctly. Any module can use it without depending on neom_ia.
///
/// Usage in a page with a bottom-right FAB:
/// ```dart
/// @override
/// void initState() { super.initState(); FabRegistry.push(); }
/// @override
/// void dispose() { FabRegistry.pop(); super.dispose(); }
/// ```
class FabRegistry {
  FabRegistry._();

  static int _count = 0;

  /// Declare that a bottom-right FAB is now on screen.
  static void push() => _count++;

  /// Declare that a previously-pushed FAB is gone.
  static void pop() {
    if (_count > 0) _count--;
  }

  /// Force-clear (e.g. on hard route resets).
  static void reset() => _count = 0;

  /// Whether at least one screen currently shows a bottom-right FAB.
  static bool get present => _count > 0;
}
