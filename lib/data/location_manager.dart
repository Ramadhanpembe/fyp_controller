import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationManager {
  static double distanceBetween({required LatLng latLng1, required LatLng latLng2}) {
    return Geolocator.distanceBetween(
        latLng1.latitude, latLng1.longitude, latLng2.latitude, latLng2.longitude);
  }
}
