import 'package:flutter/widgets.dart';

import '../model/qr_scan_models.dart';

/// Contrato de dominio para lectura de códigos QR y códigos de barras 2D.
///
/// Permite que módulos como `neom_events`, `neom_booking`, `neom_pos`,
/// `neom_stripe`, `neom_rc` o `neom_profile` consuman lectura QR sin acoplarse
/// directamente a `mobile_scanner`. La implementación concreta reside en
/// `neom_scanner`.
abstract class QrScannerService {
  /// Indica si la plataforma actual soporta vista previa de cámara en vivo
  /// para escaneo QR (por ejemplo `false` en Windows/Linux sin plugin nativo).
  bool get isCameraSupported;

  /// Construye un visor embebible de cámara QR para pantallas que muestran su
  /// propio marco/estado superpuesto (boletaje de eventos, pases de reserva,
  /// emparejamiento remoto SAIA, etc.).
  Widget buildScannerViewport({
    required ValueChanged<String> onDetect,
    bool frontCamera = false,
    Key? key,
  });

  /// Abre el flujo universal de escaneo QR (`/qr/scanner`) y devuelve el
  /// [QrScanResult] leído, o redirige automáticamente a
  /// [QrScanArguments.destinationRoute] cuando se especifica una dirección destino.
  Future<QrScanResult?> scanCode([
    QrScanArguments arguments = const QrScanArguments(),
  ]);
}
