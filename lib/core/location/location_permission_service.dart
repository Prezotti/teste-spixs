import 'package:geolocator/geolocator.dart';

class LocationPermissionService {
  Future<bool> isGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return _isGranted(permission);
    } catch (_) {
      return false;
    }
  }

  Future<bool> request() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return _isGranted(permission);
  }

  Future<Position?> currentOrLast() async {
    if (!await isGranted()) return null;

    try {
      final last = await Geolocator.getLastKnownPosition().timeout(
        const Duration(milliseconds: 400),
        onTimeout: () => null,
      );
      if (last != null) return last;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  bool _isGranted(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
