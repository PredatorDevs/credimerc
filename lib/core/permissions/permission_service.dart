import 'package:permission_handler/permission_handler.dart';

enum MediaPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class PermissionService {
  Future<MediaPermissionResult> requestMediaPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();

    final statuses = <PermissionStatus>[cameraStatus, photosStatus];

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

  Future<bool> openSettings() {
    return openAppSettings();
  }
}
