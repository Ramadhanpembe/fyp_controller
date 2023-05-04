import 'package:fyp_controller/data/resources.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationManager {
  LocationManager() {
    _init();
  }

  void _init() async {
    isPermissionGranted = await _requestLocationPermission();
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service is disabled');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission is denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permission is permanently denied, we cannot request permission');
    }
    return true;
  }

  static double distanceBetween({required LatLng latLng1, required LatLng latLng2}) {
    return Geolocator.distanceBetween(
        latLng1.latitude, latLng1.longitude, latLng2.latitude, latLng2.longitude);
  }
}
