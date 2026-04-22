// lib/core/services/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationController = StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();

    if (status.isDenied) {
      return false;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  void startTracking({
    int intervalSeconds = 10, // Send location every 10 seconds
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update when user moves 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        _locationController.add(position);
      },
      onError: (error) {
        print('Location error: $error');
      },
    );
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationController.close();
  }
}