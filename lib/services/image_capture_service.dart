import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageCaptureResult {
  final File? file;
  final String? message;
  final bool cancelled;
  final bool shouldOpenSettings;

  const ImageCaptureResult({
    this.file,
    this.message,
    this.cancelled = false,
    this.shouldOpenSettings = false,
  });
}

class ImageCaptureService {
  ImageCaptureService._();

  static const int defaultMaxDimension = 1600;
  static const int defaultQuality = 72;
  static const int defaultMaxBytes = 3 * 1024 * 1024;

  static Future<ImageCaptureResult> pickAndCompressImage({
    required ImageSource source,
    ImagePicker? picker,
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
    int maxBytes = defaultMaxBytes,
  }) async {
    final permission = await _ensurePermission(source);
    if (!permission.granted) {
      return ImageCaptureResult(
        message: permission.message,
        shouldOpenSettings: permission.permanentlyDenied,
      );
    }

    try {
      final activePicker = picker ?? ImagePicker();
      final XFile? picked = await activePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: maxDimension.toDouble(),
        maxHeight: maxDimension.toDouble(),
        requestFullMetadata: false,
      );

      if (picked == null) {
        return const ImageCaptureResult(cancelled: true);
      }

      final File sourceFile = File(picked.path);
      File processed = sourceFile;
      bool processedIsTempFile = false;

      final File? firstCompressed = await _compress(
        source: sourceFile,
        quality: quality,
        maxDimension: maxDimension,
      );
      if (firstCompressed != null) {
        processed = firstCompressed;
        processedIsTempFile = true;
      }

      int bytes = _safeLength(processed);
      if (bytes > maxBytes) {
        final File previousProcessed = processed;
        final File? secondCompressed = await _compress(
          source: processed,
          quality: quality > 55 ? 55 : quality.clamp(40, 55).toInt(),
          maxDimension: 1280,
        );
        if (secondCompressed != null) {
          if (processedIsTempFile) {
            await tryDelete(previousProcessed);
          }
          processed = secondCompressed;
          processedIsTempFile = true;
          bytes = _safeLength(processed);
        }
      }

      if (bytes > maxBytes) {
        if (processedIsTempFile) {
          await tryDelete(processed);
        }
        return ImageCaptureResult(
          message: 'Image is too large. Please choose a smaller image.',
        );
      }

      return ImageCaptureResult(file: processed);
    } on PlatformException {
      return const ImageCaptureResult(
        message: 'Unable to access camera/gallery right now. Please try again.',
      );
    } catch (_) {
      return const ImageCaptureResult(
        message: 'Failed to process image. Please try again.',
      );
    }
  }

  static int safeLength(File file) => _safeLength(file);

  static Future<void> tryDelete(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  static Future<File?> _compress({
    required File source,
    required int quality,
    required int maxDimension,
  }) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath =
          '${tempDir.path}/img_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) return null;
      return File(compressed.path);
    } catch (_) {
      return null;
    }
  }

  static int _safeLength(File file) {
    try {
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  static Future<_PermissionOutcome> _ensurePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return _ensureCameraPermission();
    }

    if (Platform.isIOS) {
      return _ensureIosGalleryPermission();
    }

    if (Platform.isAndroid) {
      return _ensureAndroidGalleryPermission();
    }

    return const _PermissionOutcome(
      granted: false,
      message: 'Storage/Photos permission was denied.',
    );
  }

  static Future<_PermissionOutcome> _ensureCameraPermission() async {
    final PermissionStatus currentStatus = await Permission.camera.status;
    if (currentStatus.isGranted) {
      return const _PermissionOutcome(granted: true);
    }

    final PermissionStatus requestStatus = await Permission.camera.request();
    if (requestStatus.isGranted) {
      return const _PermissionOutcome(granted: true);
    }

    if (_isPermanentlyDenied(requestStatus)) {
      return const _PermissionOutcome(
        granted: false,
        permanentlyDenied: true,
        message: 'Camera permission is permanently denied.',
      );
    }

    return const _PermissionOutcome(
      granted: false,
      message: 'Camera permission was denied.',
    );
  }

  static Future<_PermissionOutcome> _ensureIosGalleryPermission() async {
    final PermissionStatus currentStatus = await Permission.photos.status;
    if (currentStatus.isGranted || currentStatus.isLimited) {
      return const _PermissionOutcome(granted: true);
    }

    final PermissionStatus requestStatus = await Permission.photos.request();
    if (requestStatus.isGranted || requestStatus.isLimited) {
      return const _PermissionOutcome(granted: true);
    }

    if (_isPermanentlyDenied(requestStatus)) {
      return const _PermissionOutcome(
        granted: false,
        permanentlyDenied: true,
        message: 'Photo library permission is permanently denied.',
      );
    }

    return const _PermissionOutcome(
      granted: false,
      message: 'Photo library permission was denied.',
    );
  }

  static Future<_PermissionOutcome> _ensureAndroidGalleryPermission() async {
    final PermissionStatus currentPhotosStatus = await Permission.photos.status;
    if (currentPhotosStatus.isGranted || currentPhotosStatus.isLimited) {
      return const _PermissionOutcome(granted: true);
    }

    final PermissionStatus requestPhotosStatus = await Permission.photos.request();
    if (requestPhotosStatus.isGranted || requestPhotosStatus.isLimited) {
      return const _PermissionOutcome(granted: true);
    }

    final PermissionStatus currentStorageStatus = await Permission.storage.status;
    if (currentStorageStatus.isGranted) {
      return const _PermissionOutcome(granted: true);
    }

    final PermissionStatus requestStorageStatus = await Permission.storage.request();
    if (requestStorageStatus.isGranted) {
      return const _PermissionOutcome(granted: true);
    }

    if (_isPermanentlyDenied(requestPhotosStatus) ||
        _isPermanentlyDenied(requestStorageStatus)) {
      return const _PermissionOutcome(
        granted: false,
        permanentlyDenied: true,
        message: 'Photo access is permanently denied. Please enable it in app settings.',
      );
    }

    return const _PermissionOutcome(
      granted: false,
      message: 'Photo access was denied.',
    );
  }

  static bool _isPermanentlyDenied(PermissionStatus status) {
    return status.isPermanentlyDenied || status.isRestricted;
  }
}

class _PermissionOutcome {
  final bool granted;
  final bool permanentlyDenied;
  final String? message;

  const _PermissionOutcome({
    required this.granted,
    this.permanentlyDenied = false,
    this.message,
  });
}
