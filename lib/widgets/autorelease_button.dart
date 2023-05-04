import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_controller/data/location_manager.dart';
import 'package:fyp_controller/data/resources.dart';
import 'package:fyp_controller/models/driver_info.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class AutoreleaseButton extends StatelessWidget {
  const AutoreleaseButton({
    super.key,
    required this.onHover,
    required this.isFocused,
  });

  final Function(bool?) onHover;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 18.0, right: 8.0),
      child: ValueListenableBuilder<ReleaseButtonState>(
        valueListenable: autoreleaseButtonNotifier,
        builder: (_, val, __) {
          switch (val) {
            case ReleaseButtonState.manualRelease:
              return FilledButton(
                onHover: (value) => onHover(value),
                style: ButtonStyle(
                  backgroundColor: isFocused
                      ? MaterialStateProperty.all(Colors.grey)
                      : MaterialStateProperty.all(Colors.white),
                  elevation: MaterialStateProperty.all(20.0),
                  visualDensity: VisualDensity.comfortable,
                ),
                onPressed: () async {
                  autoreleaseButtonNotifier.value = ReleaseButtonState.autoRelease;
                  _autoNotifyDriver();
                },
                child: Text(
                  'AUTO RELEASE OFF',
                  style: TextStyle(color: isFocused ? Colors.white : Colors.black),
                ),
              );
            case ReleaseButtonState.autoRelease:
              return FilledButton(
                onHover: (value) => onHover(value),
                style: ButtonStyle(
                  backgroundColor: isFocused
                      ? MaterialStateProperty.all(Colors.grey)
                      : MaterialStateProperty.all(Colors.red),
                  elevation: MaterialStateProperty.all(20.0),
                  visualDensity: VisualDensity.comfortable,
                  // foregroundColor: MaterialStateProperty.all(Colors.black),
                ),
                onPressed: () {
                  autoreleaseButtonNotifier.value = ReleaseButtonState.manualRelease;
                },
                child: Text(
                  'AUTO RELEASE ON',
                  style: TextStyle(color: isFocused ? Colors.white : Colors.black),
                ),
              );
          }
        },
      ),
    );
  }

  void _autoNotifyDriver() async {
    /// call onPressed here and listen for the totalRequest notifier of any of
    /// the available route
    for (int i = 0; i < totalRequestsNotifiers.length; i++) {
      if (totalRequestsNotifiers[i].value >= 20) {
        /// 20 is hardcoded here which indicates the number of request up to which
        /// a bus should be released, this number is planned to change anytime when
        /// needed.
        final QuerySnapshot routeQuerySnapshot = await firestoreManager.getAllRoutes();
        final List<QueryDocumentSnapshot> routeDocs = routeQuerySnapshot.docs;

        /// here I have got a specific route that has a high demand
        final QueryDocumentSnapshot myRouteDoc = routeDocs.elementAt(i);

        /// Fetch all drivers and select all drivers of only this selected route
        final QuerySnapshot driverQuerySnapshot = await firestoreManager.getAllDrivers();
        final List<QueryDocumentSnapshot> driverDocs = driverQuerySnapshot.docs;
        final List<QueryDocumentSnapshot> requiredDriverDocs = [];

        for (var driverDoc in driverDocs) {
          if (driverDoc['route']['from_terminal'] == myRouteDoc['from_terminal'] &&
              driverDoc['route']['to_terminal'] == myRouteDoc['to_terminal']) {
            requiredDriverDocs.add(driverDoc);
          }
        }

        /// Now we have a list of all drivers who we want to notify them,
        /// [requiredDriverDocs], use this list for your logic to notify one driver.
        // TODO: Were here now.
        List<QueryDocumentSnapshot> inStationDrivers = [];
        if (isPermissionGranted) {
          final stationPosition = await Geolocator.getCurrentPosition();
          final stationLatLng = LatLng(stationPosition.latitude, stationPosition.longitude);
          for (var driverDoc in requiredDriverDocs) {
            final driverLatLng =
                LatLng(driverDoc['location']['latitude'], driverDoc['location']['longitude']);
            final double distanceBetween =
                LocationManager.distanceBetween(latLng1: stationLatLng, latLng2: driverLatLng);
            if (distanceBetween <= 200.0) inStationDrivers.add(driverDoc);
          }
        }

        /// Now we have all drivers who are less than 200m between them and the
        /// main station.
        List<int> timestamps = [];
        for (var driver in inStationDrivers) {
          timestamps.add(DateTime.parse(driver['location']['timestamp']).millisecondsSinceEpoch);
        }
        timestamps.sort();

        /// here we need [timestamps.first], the earliest one
        final int timestampOfRequiredDriver = timestamps.first;

        for (var driver in inStationDrivers) {
          if (DateTime.parse(driver['location']['timestamp']).millisecondsSinceEpoch ==
              timestampOfRequiredDriver) {
            firestoreManager.sendNotification(driver['login']['phone']);
            await _checkDriverMotion(DriverInfo(
              username: driver['username'],
              phone: driver['login']['phone'],
              fromTerminal: driver['route']['from_terminal'],
              toTerminal: driver['route']['to_terminal'],
              latitude: driver['location']['latitude'],
              longitude: driver['location']['longitude'],
              timestamp: driver['location']['timestamp'],
            ));
          }
        }
      }
    }
  }

  Future<void> _checkDriverMotion(DriverInfo driverInfo) async {
    final Map<String, double> initialPosition =
        await firestoreManager.getDriverCurrentLocation(driverInfo);
    final LatLng latLng1 =
        LatLng(initialPosition['latitude'] ?? 0.0, initialPosition['longitude'] ?? 0.0);
    Map<String, double> finalPosition = {};
    bool isMoving = await Future.delayed(const Duration(minutes: 2), () async {
      bool moving = true;
      finalPosition = await firestoreManager.getDriverCurrentLocation(driverInfo);
      final LatLng latLng2 =
          LatLng(finalPosition['latitude'] ?? 0.0, finalPosition['longitude'] ?? 0.0);
      final double travelledDistance =
          LocationManager.distanceBetween(latLng1: latLng1, latLng2: latLng2);
      if (travelledDistance < 100) {
        moving = false;
        _autoNotifyDriver();
      }
      return moving;
    });
    driverIsMoving = isMoving;
    driverPhone = driverInfo.phone;
  }
}
