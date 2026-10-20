import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Gestion des permissions et de l'état de la localisation.
class LocationPermissionService {
  /// Vérifie et demande la permission de localisation.
  /// Retourne true si la localisation est utilisable.
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Comme ensurePermission mais distingue le refus définitif.
  Future<LocationAccessResult> ensurePermissionDetailed() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessResult.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        return LocationAccessResult.denied;
      case LocationPermission.deniedForever:
        return LocationAccessResult.permanentlyDenied;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationAccessResult.granted;
      case LocationPermission.unableToDetermine:
        return LocationAccessResult.denied;
    }
  }

  Future<Position?> currentPosition({
    bool exact = true,
  }) async {
    final ok = await ensurePermission();
    if (!ok) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: exact
            ? const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 15),
              ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  Future<void> openApplicationSettings() => openAppSettings();
}

enum LocationAccessResult { granted, denied, permanentlyDenied, serviceDisabled }
