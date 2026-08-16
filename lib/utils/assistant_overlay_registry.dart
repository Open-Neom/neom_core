import 'package:sint/sint.dart';

/// Global, dependency-free registry signaling the open/closed state of the
/// AI Assistant (Itzli/Saia) floating panel.
///
/// Other floating components (like the web miniplayer or FABs) can observe
/// [isOpen] to make space so they never overlap.
class AssistantOverlayRegistry {
  AssistantOverlayRegistry._();

  /// Reactive boolean indicating whether the assistant chat panel is open.
  static final RxBool isOpen = false.obs;

  /// Update the open state.
  static void setOpen(bool value) {
    isOpen.value = value;
  }
}
