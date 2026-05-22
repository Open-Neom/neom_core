import 'package:flutter/material.dart';

/// Wrapper that loads a deferred library before rendering its child.
///
/// Used with Dart's `deferred as` imports to enable code splitting on web.
/// The WASM/JS compiler splits each deferred import into a separate
/// chunk (.part.wasm / .part.js) that is only downloaded when
/// [libraryLoader] is called — i.e. when the user first navigates
/// to the route that uses this widget.
///
/// On native platforms (iOS, Android, macOS, Windows, Linux),
/// [libraryLoader] resolves instantly (no-op) so this widget is transparent.
///
/// ## Usage in a module's `*_routes.dart`:
///
/// ```dart
/// import 'package:neom_core/ui/deferred_loader.dart';
/// import 'ui/erp_dashboard_page.dart' deferred as erp_dash;
///
/// class ErpRoutes {
///   static List<SintPage> get routes => [
///     SintPage(
///       name: '/erp',
///       page: () => DeferredLoader(
///         erp_dash.loadLibrary,
///         () => erp_dash.ErpDashboardPage(),
///       ),
///     ),
///   ];
/// }
/// ```
class DeferredLoader extends StatelessWidget {
  final Future<void> Function() libraryLoader;
  final Widget Function() builder;

  const DeferredLoader(this.libraryLoader, this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: libraryLoader(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading module',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }
          return builder();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
