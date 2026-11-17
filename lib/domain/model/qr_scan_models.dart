/// Formatos soportados de forma desacoplada por el escáner universal
/// (`neom_scanner`), evitando acoplar módulos de dominio a `mobile_scanner`.
enum NeomBarcodeFormat {
  qrCode,
  ean13,
  ean8,
  upcA,
  upcE,
  code128,
  code39,
  pdf417,
}

/// Argumentos desacoplados para invocar el escáner QR universal (`neom_scanner`)
/// desde cualquier sección del ecosistema (eventos, pagos/POS, reservas,
/// facturación SAT/ERP, vinculación remota SAIA, perfiles, etc.) ya sea por
/// `Sint.arguments` o por parámetros de URL (`/qr/scanner?origin=events&next=/event/ticket-scanner`).
class QrScanArguments {
  final String origin;
  final String? destinationRoute;
  final String? title;
  final String? hint;
  final String? manualInputHint;
  final bool frontCamera;
  final bool allowManualInput;
  final bool enableHaptics;
  final Set<NeomBarcodeFormat> formats;
  final Map<String, dynamic> parameters;

  const QrScanArguments({
    this.origin = '',
    this.destinationRoute,
    this.title,
    this.hint,
    this.manualInputHint,
    this.frontCamera = false,
    this.allowManualInput = true,
    this.enableHaptics = true,
    this.formats = const {},
    this.parameters = const {},
  });

  /// Preset optimizado exclusivamente para códigos QR 2D (boletos, reservas, pases).
  factory QrScanArguments.qrOnly({
    String origin = '',
    String? destinationRoute,
    String? title,
    String? hint,
    String? manualInputHint,
    bool frontCamera = false,
    bool allowManualInput = true,
    Map<String, dynamic> parameters = const {},
  }) {
    return QrScanArguments(
      origin: origin,
      destinationRoute: destinationRoute,
      title: title ?? 'Escanear código QR',
      hint: hint ?? 'Alinea el código QR dentro del recuadro',
      manualInputHint: manualInputHint,
      frontCamera: frontCamera,
      allowManualInput: allowManualInput,
      formats: const {NeomBarcodeFormat.qrCode},
      parameters: parameters,
    );
  }

  /// Preset optimizado para punto de venta editorial y catálogo (ISBN / EAN-13 + QR).
  factory QrScanArguments.retailBarcode({
    String origin = 'pos_catalog',
    String? title,
    String? hint,
    bool allowManualInput = true,
    Map<String, dynamic> parameters = const {},
  }) {
    return QrScanArguments(
      origin: origin,
      title: title ?? 'Escanear ISBN o código de producto',
      hint: hint ?? 'Alinea el código de barras ISBN (EAN-13) o código QR',
      manualInputHint: 'Ej. 9786071234567 o SKU del producto',
      allowManualInput: allowManualInput,
      formats: const {
        NeomBarcodeFormat.ean13,
        NeomBarcodeFormat.ean8,
        NeomBarcodeFormat.upcA,
        NeomBarcodeFormat.upcE,
        NeomBarcodeFormat.code128,
        NeomBarcodeFormat.qrCode,
      },
      parameters: parameters,
    );
  }

  /// Preset optimizado para lectura de Constancia de Situación Fiscal (CSF) o CFDI SAT.
  factory QrScanArguments.satFiscalQr({
    String origin = 'sat_fiscal',
    String? title,
    String? hint,
    bool allowManualInput = true,
    Map<String, dynamic> parameters = const {},
  }) {
    return QrScanArguments(
      origin: origin,
      title: title ?? 'Escanear QR Fiscal SAT',
      hint: hint ?? 'Escanea el código QR de la Constancia SAT o factura CFDI',
      manualInputHint: 'URL del QR SAT o RFC del contribuyente',
      allowManualInput: allowManualInput,
      formats: const {NeomBarcodeFormat.qrCode},
      parameters: parameters,
    );
  }

  bool get prefersLinearReticle =>
      formats.isNotEmpty &&
      (formats.contains(NeomBarcodeFormat.ean13) ||
          formats.contains(NeomBarcodeFormat.ean8) ||
          formats.contains(NeomBarcodeFormat.upcA) ||
          formats.contains(NeomBarcodeFormat.code128));

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
        manualInputHint:
            arguments.manualInputHint ?? routeParameters['manualHint'],
        frontCamera:
            arguments.frontCamera || routeParameters['camera'] == 'front',
        allowManualInput:
            arguments.allowManualInput && routeParameters['manual'] != 'false',
        enableHaptics: arguments.enableHaptics,
        formats: arguments.formats,
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
        manualInputHint:
            (map['manualInputHint'] as String?) ??
            routeParameters['manualHint'],
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
      manualInputHint: routeParameters['manualHint'],
      frontCamera: routeParameters['camera'] == 'front',
      allowManualInput: routeParameters['manual'] != 'false',
      parameters: cleanQuery,
    );
  }
}

/// Resultado tipado de una lectura QR / código de barras (por cámara o ingreso manual),
/// conservando el origen, formato detectado, ruta destino y parámetros asociados.
class QrScanResult {
  final String rawValue;
  final String origin;
  final String? destinationRoute;
  final bool isManualInput;
  final NeomBarcodeFormat? detectedFormat;
  final DateTime scannedAt;
  final Map<String, dynamic> parameters;

  QrScanResult({
    required this.rawValue,
    this.origin = '',
    this.destinationRoute,
    this.isManualInput = false,
    this.detectedFormat,
    DateTime? scannedAt,
    this.parameters = const {},
  }) : scannedAt = scannedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'rawValue': rawValue,
    'origin': origin,
    if (destinationRoute != null) 'destinationRoute': destinationRoute,
    'isManualInput': isManualInput,
    if (detectedFormat != null) 'detectedFormat': detectedFormat!.name,
    'scannedAt': scannedAt.toIso8601String(),
    'parameters': parameters,
  };

  factory QrScanResult.fromJson(Map<String, dynamic> json) {
    final rawParams = json['parameters'];
    final rawFmt = json['detectedFormat'] as String?;
    NeomBarcodeFormat? parsedFormat;
    if (rawFmt != null && rawFmt.isNotEmpty) {
      for (final candidate in NeomBarcodeFormat.values) {
        if (candidate.name == rawFmt) {
          parsedFormat = candidate;
          break;
        }
      }
    }
    return QrScanResult(
      rawValue: (json['rawValue'] as String?) ?? '',
      origin: (json['origin'] as String?) ?? '',
      destinationRoute: json['destinationRoute'] as String?,
      isManualInput: (json['isManualInput'] as bool?) ?? false,
      detectedFormat: parsedFormat,
      scannedAt:
          DateTime.tryParse((json['scannedAt'] as String?) ?? '') ??
          DateTime.now(),
      parameters: rawParams is Map
          ? Map<String, dynamic>.from(rawParams)
          : const {},
    );
  }
}
