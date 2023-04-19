import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_controller/data/resources.dart';
import 'package:fyp_controller/models/driver_location.dart';
import 'package:latlong2/latlong.dart';

import '../utils/constants.dart';

class MapContainer extends StatefulWidget {
  const MapContainer({
    super.key,
    required this.mapController,
    required this.location,
  });

  final MapController mapController;
  final LatLng location;

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  late final Stream<QuerySnapshot> _locationStream;

  @override
  void initState() {
    _locationStream = firestoreManager.listenOnDriverLocationUpdates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          center: widget.location,
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
          StreamBuilder(
            stream: _locationStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                return Container();
              }
              if (snapshot.hasData) {
                List<DriverLocation> driverLocations = [];
                final QuerySnapshot querySnapshot = snapshot.data!;
                final List<QueryDocumentSnapshot> driverDocs = querySnapshot.docs;
                for (var driverDoc in driverDocs) {
                  driverLocations.add(DriverLocation(
                    latitude: driverDoc['location']['latitude'],
                    longitude: driverDoc['location']['longitude'],
                    accuracy: driverDoc['location']['accuracy'],
                    speed: driverDoc['location']['speed'],
                  ));
                }
                return MarkerLayer(
                  markers: _getDriverPositionMarkers(driverLocations),
                );
              }
              return Container();
            },
          ),
          MarkerLayer(
            markers: [
              _buildMarker(
                point: widget.location,
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
      IconData? icon = Icons.circle}) {
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

  List<Marker> _getDriverPositionMarkers(List<DriverLocation> locations) {
    List<Marker> markers = [];
    List<LatLng> latlngs = [];
    for (var location in locations) {
      latlngs.add(LatLng(location.latitude, location.longitude));
    }
    for (var latlng in latlngs) {
      markers.add(_buildMarker(point: latlng));
    }
    return markers;
  }
}
