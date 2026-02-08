import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

/// Define el contrato para un servicio de cámara, exponiendo las acciones
/// y el estado necesarios para que la UI interactúe con la cámara del dispositivo.
abstract class AppCameraService {

  bool isInitialized();
  Future<void> initializeCameraController();

  /// Initialize camera with front-facing camera specifically
  /// Used for video reactions, selfie mode, etc.
  Future<void> initializeFrontCamera();

  void onTakePictureButtonPressed();
  void onFlashModeButtonPressed();
  void onAudioModeButtonPressed();
  void onVideoRecordButtonPressed();
  void onStopButtonPressed();
  void onPauseButtonPressed();
  void onResumeButtonPressed();
  Widget cameraPreviewWidget();

  Future<File?> takePicture();
  Future<void> startVideoRecording();
  Future<File?> stopVideoRecording();
  Future<void> pauseVideoRecording();
  Future<void> resumeVideoRecording();
  bool get isDisposed;

}
