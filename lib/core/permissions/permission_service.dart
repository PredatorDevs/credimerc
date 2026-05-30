import 'package:permission_handler/permission_handler.dart';

enum MediaPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class PermissionService {
  Future<MediaPermissionResult> requestCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    return _mapResult(<PermissionStatus>[cameraStatus]);
  }

  Future<MediaPermissionResult> requestPhotosPermission() async {
    final photosStatus = await Permission.photos.request();
    if (photosStatus == PermissionStatus.granted || photosStatus == PermissionStatus.limited) {
      return MediaPermissionResult.granted;
    }

    final storageStatus = await Permission.storage.request();
    return _mapResult(<PermissionStatus>[photosStatus, storageStatus]);
  }

  Future<MediaPermissionResult> requestMediaPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosResult = await requestPhotosPermission();
    if (photosResult != MediaPermissionResult.granted) {
      return photosResult;
    }

    return _mapResult(<PermissionStatus>[cameraStatus]);
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }

  MediaPermissionResult _mapResult(List<PermissionStatus> statuses) {
    final allGranted = statuses.every(
      (PermissionStatus status) =>
          status == PermissionStatus.granted || status == PermissionStatus.limited,
    );
    if (allGranted) {
      return MediaPermissionResult.granted;
    }

    final hasPermanentDenial = statuses.any(
      (PermissionStatus status) => status == PermissionStatus.permanentlyDenied,
    );
    if (hasPermanentDenial) {
      return MediaPermissionResult.permanentlyDenied;
    }

    return MediaPermissionResult.denied;
  }
}
