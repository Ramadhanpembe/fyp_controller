import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_controller/data/resources.dart';
import 'package:latlong2/latlong.dart';

import '../utils/constants.dart';

class MapContainer extends StatelessWidget {
  const MapContainer({
    super.key,
    required this.mapController,
    required this.location,
  });

  final MapController mapController;
  final LatLng location;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: location,
          zoom: 13,
          keepAlive: true,
          scrollWheelVelocity: 0.001,
          enableScrollWheel: true,
        ),
        children: [
          TileLayer(
            urlTemplate: '$tomtomUrl/1/tile/basic/main/{z}/{x}/{y}.png?key=$apiKey',
            additionalOptions: const {'apiKey': apiKey},
          ),
          FutureBuilder<List<Marker>>(
            future: _driverPositions,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return MarkerLayer(
                  markers: snapshot.data!,
                );
              }
              return const Text('No data found');
            },
          ),
          MarkerLayer(
            markers: [
              _buildMarker(
                point: location,
                color: Colors.black,
                icon: Icons.my_location,
                size: 48.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(
      {required LatLng point,
      double size = 32.0,
      Color? color = kPositionIconColor,
      IconData? icon = Icons.airport_shuttle}) {
    return Marker(
        width: 40.0,
        height: 40.0,
        point: point,
        rotate: true,
        builder: (BuildContext context) {
          return Icon(
            icon,
            size: size,
            color: color,
          );
        });
  }

  Future<List<Marker>> get _driverPositions async {
    List<Marker> markers = [];
    List<LatLng> latlngs = await firestoreManager.getExistingDriverLocations();
    for (var latlng in latlngs) {
      markers.add(_buildMarker(point: latlng));
    }
    return markers;
  }
}
