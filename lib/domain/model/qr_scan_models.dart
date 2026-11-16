/// Argumentos desacoplados para invocar el escáner QR universal (`neom_scanner`)
/// desde cualquier sección del ecosistema (eventos, pagos/POS, reservas,
/// vinculación remota SAIA, perfiles, etc.) ya sea por `Sint.arguments` o por
/// parámetros de URL (`/qr/scanner?origin=events&next=/event/ticket-scanner`).
class QrScanArguments {
  final String origin;
  final String? destinationRoute;
  final String? title;
  final String? hint;
  final bool frontCamera;
  final bool allowManualInput;
  final Map<String, dynamic> parameters;

  const QrScanArguments({
    this.origin = '',
    this.destinationRoute,
    this.title,
    this.hint,
    this.frontCamera = false,
    this.allowManualInput = true,
    this.parameters = const {},
  });

  /// Construye [QrScanArguments] combinando argumentos de ruta (`Sint.arguments`)
  /// y parámetros de dirección URL (`Sint.parameters`).
  factory QrScanArguments.fromRoute({
    Object? arguments,
    Map<String, String?> routeParameters = const {},
  }) {
    final cleanQuery = <String, dynamic>{
      for (final entry in routeParameters.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value,
    };

    if (arguments is QrScanArguments) {
      return QrScanArguments(
        origin: arguments.origin.isNotEmpty
            ? arguments.origin
            : (routeParameters['origin'] ?? routeParameters['section'] ?? ''),
        destinationRoute:
            arguments.destinationRoute ??
            routeParameters['next'] ??
            routeParameters['route'],
        title: arguments.title ?? routeParameters['title'],
        hint: arguments.hint ?? routeParameters['hint'],
        frontCamera:
            arguments.frontCamera || routeParameters['camera'] == 'front',
        allowManualInput:
            arguments.allowManualInput && routeParameters['manual'] != 'false',
        parameters: {...cleanQuery, ...arguments.parameters},
      );
    }

    if (arguments is Map) {
      final map = Map<String, dynamic>.from(arguments);
      final rawParams = map['parameters'];
      final extraParams = rawParams is Map
          ? Map<String, dynamic>.from(rawParams)
          : <String, dynamic>{};
      return QrScanArguments(
        origin:
            (map['origin'] as String?) ??
            (map['section'] as String?) ??
            routeParameters['origin'] ??
            routeParameters['section'] ??
            '',
        destinationRoute:
            (map['destinationRoute'] as String?) ??
            (map['next'] as String?) ??
            routeParameters['next'] ??
            routeParameters['route'],
        title: (map['title'] as String?) ?? routeParameters['title'],
        hint: (map['hint'] as String?) ?? routeParameters['hint'],
        frontCamera:
            (map['frontCamera'] as bool?) ??
            (routeParameters['camera'] == 'front'),
        allowManualInput:
            (map['allowManualInput'] as bool?) ??
            (routeParameters['manual'] != 'false'),
        parameters: {...cleanQuery, ...map, ...extraParams},
      );
    }

    return QrScanArguments(
      origin: routeParameters['origin'] ?? routeParameters['section'] ?? '',
      destinationRoute: routeParameters['next'] ?? routeParameters['route'],
      title: routeParameters['title'],
      hint: routeParameters['hint'],
      frontCamera: routeParameters['camera'] == 'front',
      allowManualInput: routeParameters['manual'] != 'false',
      parameters: cleanQuery,
    );
  }
}

/// Resultado tipado de una lectura QR (por cámara o ingreso manual de respaldo),
/// conservando el origen, la ruta destino y los parámetros asociados.
class QrScanResult {
  final String rawValue;
  final String origin;
  final String? destinationRoute;
  final bool isManualInput;
  final DateTime scannedAt;
  final Map<String, dynamic> parameters;

  QrScanResult({
    required this.rawValue,
    this.origin = '',
    this.destinationRoute,
    this.isManualInput = false,
    DateTime? scannedAt,
    this.parameters = const {},
  }) : scannedAt = scannedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'rawValue': rawValue,
    'origin': origin,
    if (destinationRoute != null) 'destinationRoute': destinationRoute,
    'isManualInput': isManualInput,
    'scannedAt': scannedAt.toIso8601String(),
    'parameters': parameters,
  };

  factory QrScanResult.fromJson(Map<String, dynamic> json) {
    final rawParams = json['parameters'];
    return QrScanResult(
      rawValue: (json['rawValue'] as String?) ?? '',
      origin: (json['origin'] as String?) ?? '',
      destinationRoute: json['destinationRoute'] as String?,
      isManualInput: (json['isManualInput'] as bool?) ?? false,
      scannedAt:
          DateTime.tryParse((json['scannedAt'] as String?) ?? '') ??
          DateTime.now(),
      parameters: rawParams is Map
          ? Map<String, dynamic>.from(rawParams)
          : const {},
    );
  }
}
