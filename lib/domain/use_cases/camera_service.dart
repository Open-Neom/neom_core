import 'dart:async';
import 'dart:io';

/// Define el contrato para un servicio de cámara, exponiendo las acciones
/// y el estado necesarios para que la UI interactúe con la cámara del dispositivo.
abstract class AppCameraService {

  bool isInitialized();
  Future<void> initializeCameraController();

  void onTakePictureButtonPressed();
  void onFlashModeButtonPressed();
  void onAudioModeButtonPressed();
  void onVideoRecordButtonPressed();
  void onStopButtonPressed();
  void onPauseButtonPressed();
  void onResumeButtonPressed();

  Future<File?> takePicture();
  Future<void> startVideoRecording();
  Future<File?> stopVideoRecording();
  Future<void> pauseVideoRecording();
  Future<void> resumeVideoRecording();
  bool get isDisposed;

}
