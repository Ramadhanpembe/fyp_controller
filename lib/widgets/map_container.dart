import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:fyp_controller/data/map_manager.dart';
import 'package:fyp_controller/data/resources.dart';
import 'package:fyp_controller/models/driver_location.dart';
import 'package:latlong2/latlong.dart';

import '../utils/constants.dart';

class MapContainer extends StatefulWidget {
  const MapContainer({
    super.key,
    required this.mapController,
    required this.fromTerminalLocation,
    required this.toTerminalLocation,
  });

  final MapController mapController;
  final LatLng fromTerminalLocation;
  final LatLng toTerminalLocation;

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  late final Stream<QuerySnapshot> _locationStream;
  List<LatLng> _routeCoordinates = [];
  late final _fromTerminalLocation = widget.fromTerminalLocation;
  late final _toTerminalLocation = widget.toTerminalLocation;

  void _getRouteCoordinates() async {
    _routeCoordinates = await MapManager.calculateRoute(
        startPosition: _fromTerminalLocation, endPosition: _toTerminalLocation);
    _routeCoordinates.insert(0, _fromTerminalLocation);
    _routeCoordinates.add(_toTerminalLocation);
  }

  @override
  void initState() {
    _locationStream = firestoreManager.listenOnDriverLocationUpdates();
    _getRouteCoordinates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          center: _fromTerminalLocation,
          zoom: 15,
          keepAlive: true,
          scrollWheelVelocity: 0.001,
          enableScrollWheel: true,
        ),
        children: [
          TileLayer(
            urlTemplate: '$tomtomMapUrl/1/tile/basic/main/{z}/{x}/{y}.png?key=$apiKey',
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
                point: _fromTerminalLocation,
                color: Colors.red[600],
                icon: Icons.my_location,
                size: 48.0,
              ),
              _buildMarker(
                point: _toTerminalLocation,
                color: Colors.red[600],
                icon: Icons.my_location,
                size: 48.0,
              ),
            ],
          ),
          TappablePolylineLayer(
            polylineCulling: true,
            pointerDistanceTolerance: 20,
            polylines: [
              TaggedPolyline(
                tag: 'test_polyline',
                points: _routeCoordinates,
                color: Colors.red[600],
                strokeWidth: 7.0,
              ),
            ],
            onTap: (polylines, tapPosition) {},
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
