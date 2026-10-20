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
/// Loading is attempted once per widget state, then only when the user taps
/// Retry. Parent/theme/locale rebuilds must not start more downloads. Give the
/// widget a new key when replacing it with a different module.
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
class DeferredLoader extends StatefulWidget {
  final Future<void> Function() libraryLoader;
  final Widget Function() builder;

  const DeferredLoader(this.libraryLoader, this.builder, {super.key});

  @override
  State<DeferredLoader> createState() => _DeferredLoaderState();
}

class _DeferredLoaderState extends State<DeferredLoader> {
  late Future<void> _load;
  bool _isLoading = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _load = _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    _isLoading = true;
    _attempt++;
    try {
      // An async boundary also converts synchronous loader throws into the
      // FutureBuilder's error state.
      await widget.libraryLoader();
    } catch (error) {
      if (mounted) {
        // Never log the full exception or stack: deferred download failures
        // can contain URLs with query credentials or user-specific paths.
        final type = error.runtimeType.toString().replaceAll(
          RegExp(r'[^A-Za-z0-9_]'),
          '',
        );
        final chunk = RegExp(
          r'main\.dart\.js_[0-9]+\.part\.js',
        ).firstMatch(error.toString())?.group(0);
        debugPrint(
          'DeferredLoader: load failed; attempt=$_attempt; type=$type'
          '${chunk == null ? '' : '; chunk=$chunk'}',
        );
      }
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  void _retry() {
    if (_isLoading) return;
    final nextLoad = _loadLibrary();
    setState(() {
      _load = nextLoad;
    });
  }

  void _leave() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.maybePop();
    } else {
      // A direct web link can be the only route. Popping it would leave a
      // blank page; replace it with the host app's root instead.
      navigator.pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _DeferredLoaderMessages.forLanguage(
      Localizations.localeOf(context).languageCode,
    );
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          messages.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(messages.detail, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh),
                          label: Text(messages.retry),
                        ),
                        TextButton(
                          onPressed: _leave,
                          child: Text(
                            Navigator.of(context).canPop()
                                ? messages.back
                                : messages.home,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return widget.builder();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

// neom_core cannot depend on neom_commons (which itself imports core). Resolve
// these small shared-loader messages from the ambient Flutter locale instead.
class _DeferredLoaderMessages {
  final String title;
  final String detail;
  final String retry;
  final String back;
  final String home;

  const _DeferredLoaderMessages(
    this.title,
    this.detail,
    this.retry,
    this.back,
    this.home,
  );

  static _DeferredLoaderMessages forLanguage(String language) {
    switch (language) {
      case 'es':
        return const _DeferredLoaderMessages(
          'No se pudo cargar esta sección',
          'Comprueba tu conexión e inténtalo de nuevo. Si el problema continúa, '
              'recarga la página para obtener la versión más reciente.',
          'Reintentar',
          'Volver',
          'Ir al inicio',
        );
      case 'de':
        return const _DeferredLoaderMessages(
          'Dieser Bereich konnte nicht geladen werden',
          'Prüfe deine Verbindung und versuche es erneut. Lade bei anhaltenden '
              'Problemen die Seite neu, um die neueste Version zu erhalten.',
          'Erneut versuchen',
          'Zurück',
          'Zur Startseite',
        );
      case 'fr':
        return const _DeferredLoaderMessages(
          'Impossible de charger cette section',
          'Vérifiez votre connexion et réessayez. Si le problème persiste, '
              'rechargez la page pour obtenir la dernière version.',
          'Réessayer',
          'Retour',
          'Accueil',
        );
      default:
        return const _DeferredLoaderMessages(
          'This section could not be loaded',
          'Check your connection and try again. If the problem continues, '
              'reload the page to get the latest version.',
          'Retry',
          'Go back',
          'Go to home',
        );
    }
  }
}
