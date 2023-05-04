import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_controller/data/location_manager.dart';
import 'package:fyp_controller/data/resources.dart';
import 'package:fyp_controller/models/request.dart';
import 'package:fyp_controller/models/route_info.dart';
import 'package:fyp_controller/models/terminal_location.dart';
import 'package:latlong2/latlong.dart';

import '../models/driver_info.dart';
import '../models/terminal.dart';

class FirestoreManager {
  /// Declares firestore databases.
  late final FirebaseFirestore _db;

  FirestoreManager() {
    _init();
  }

  /// Initializes firestore database.
  void _init() async {
    _db = FirebaseFirestore.instance;
  }

  // It appears to work
  void decrement() async {
    if (!driverIsMoving || driverPhone.isEmpty) return;

    /// we need current driver location here
    /// which will be iterated over terminal locations
    /// to see if it approaches any of the terminal.
    late final QueryDocumentSnapshot driver;
    final CollectionReference driverColRef = _db.collection('drivers');
    final QuerySnapshot driverQuerySnapshot = await driverColRef.get();
    final List<QueryDocumentSnapshot> driverDocs = driverQuerySnapshot.docs;
    for (var driverDoc in driverDocs) {
      if (driverDoc['login']['phone'] == driverPhone) {
        driver = driverDoc;
      }
    }
    late final QueryDocumentSnapshot route;
    final CollectionReference routeColRef = _db.collection('routes');
    final QuerySnapshot routeQuerySnapshot = await routeColRef.get();
    final List<QueryDocumentSnapshot> routeDocs = routeQuerySnapshot.docs;
    for (var routeDoc in routeDocs) {
      if (routeDoc['from_terminal'] == driver['route']['from_terminal'] &&
          routeDoc['to_terminal'] == driver['route']['to_terminal']) {
        route = routeDoc;
      }
    }
    final CollectionReference terminalColRef = route.reference.collection('terminals');
    final QuerySnapshot terminalQuerySnapshot = await terminalColRef.get();
    final List<QueryDocumentSnapshot> terminalDocs = terminalQuerySnapshot.docs;
    for (var terminalDoc in terminalDocs) {
      final driverPosition =
          LatLng(driver['location']['latitude'], driver['location']['longitude']);
      final terminalPosition = LatLng(terminalDoc['terminal_location']['terminal_latitude'],
          terminalDoc['terminal_location']['terminal_longitude']);
      final double distanceBetweenDriverAndTerminal =
          LocationManager.distanceBetween(latLng1: driverPosition, latLng2: terminalPosition);
      debugPrint('Distance Between Driver And Terminal::: $distanceBetweenDriverAndTerminal');
      if (distanceBetweenDriverAndTerminal < 500.0) {
        debugPrint('Distance is less than 20m');
        // this part is reached successfully
        final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
        final QuerySnapshot requestQuerySnapshot = await requestColRef.get();
        final List<QueryDocumentSnapshot> requestDocs = requestQuerySnapshot.docs;
        for (var requestDoc in requestDocs) {
          await _db.collection('trash').add({
            'request_id': requestDoc.id,
            'request_delete_time': DateTime.now(),
            'request_time': requestDoc['request_time'],
            'request_terminal_id': terminalDoc.id,
            'request_terminal_name': terminalDoc['terminal_name'],
          });
          requestDoc.reference.delete();
        }
      }
    }
  }

  Future<Map<String, double>> getDriverCurrentLocation(DriverInfo driverInfo) async {
    final CollectionReference driverColRef = _db.collection('drivers');
    final QuerySnapshot querySnapshot = await driverColRef.get();
    final List<QueryDocumentSnapshot> driverDocs = querySnapshot.docs;
    for (var driverDoc in driverDocs) {
      if (driverDoc['login']['phone'] == driverInfo.phone) {
        return {
          'latitude': driverDoc['location']['latitude'],
          'longitude': driverDoc['location']['longitude'],
          'timestamp': driverDoc['location']['timestamp'],
        };
      }
    }
    return {};
  }

  /// The return of this method should be listen inside [StreamBuilder] in order to get the
  /// real-time driver locations updates.
  Stream<QuerySnapshot> listenOnDriverLocationUpdates() {
    return _db.collection('drivers').snapshots();
  }

  /// The return of this method is called in [StreamBuilder] to update the values of
  /// [earliestRequestAtNotifier], [latestRequestAtNotifier] and [requestsPerTerminal].
  Stream<QuerySnapshot> listenOnRouteCollectionUpdates() {
    final CollectionReference routeColRef = _db.collection('routes');
    return routeColRef.snapshots();
  }

  /// This method returns a [Future] List of [DriverInfo] objects from the database.
  /// It is used with [CircleAvatar] and [ListView.builder] to fetch the driver information when
  /// a controller tries to release a bus.
  Future<List<DriverInfo>> getDriverInfo(RouteInfo info) async {
    List<DriverInfo> driverInfo = [];
    final CollectionReference driverColRef = _db.collection('drivers');
    final QuerySnapshot querySnapshot = await driverColRef.get();
    final List<QueryDocumentSnapshot> driverDocs = querySnapshot.docs;
    for (var driverDoc in driverDocs) {
      if (driverDoc['route']['to_terminal'] == info.toTerminal &&
          driverDoc['route']['from_terminal'] == info.fromTerminal) {
        driverInfo.add(DriverInfo(
          username: driverDoc['username'],
          phone: driverDoc['login']['phone'],
          fromTerminal: driverDoc['route']['from_terminal'],
          toTerminal: driverDoc['route']['to_terminal'],
          latitude: driverDoc['location']['latitude'],
          longitude: driverDoc['location']['longitude'],
          timestamp: driverDoc['location']['timestamp'],
        ));
      }
    }
    return driverInfo;
  }

  // here the driverID should be the same as the driver document reference ID
  /// This method is used to send notification to a single selected driver's device
  /// The [phone] parameter passed is used to identify a unique driver from a collection of
  /// drivers.
  /// It is assumed and emphasized that a [phone] number should only be used once.
  Future<void> sendNotification(String phone) async {
    final CollectionReference driverColRef = _db.collection('drivers');
    final QuerySnapshot querySnapshot = await driverColRef.get();
    final List<QueryDocumentSnapshot> driverDocs = querySnapshot.docs;

    for (var driverDoc in driverDocs) {
      if (driverDoc['login']['phone'] == phone) {
        final CollectionReference messageColRef = driverDoc.reference.collection('messages');
        final DocumentReference messageID =
            messageColRef.doc('@${DateTime.now().millisecondsSinceEpoch}@');
        messageID.set({
          'message_id': DateTime.now().toString(),
          'title': 'Hello ${driverDoc['username']},',
          'body': 'You\'ve got some requests along the way! Will you ride them?',
        });
      }
    }
  }

  /// This method will be executed periodically, to fetch the updates on the total requests per
  /// route. It updates the value of [totalRequestsNotifier] used with the [CircleAvatar] of route.
  void listenForAllRouteRequestUpdates(String routeID, List<RouteInfo> routeInfo) async {
    final int routeIndex = routeInfo.indexWhere((element) => element.reference == routeID);
    List<Request> requests = [];
    final CollectionReference terminalColRef =
        _db.collection('routes').doc(routeID).collection('terminals');
    final QuerySnapshot querySnapshot = await terminalColRef.get();
    final List<QueryDocumentSnapshot> terminalDocs = querySnapshot.docs;
    for (var terminalDoc in terminalDocs) {
      final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
      final QuerySnapshot qs = await requestColRef.get();
      final List<QueryDocumentSnapshot> requestDocs = qs.docs;
      for (var req in requestDocs) {
        requests.add(Request(requestTime: req['request_time']));
      }
    }
    final times = _getAllRequestTimesInMillisecondsSinceEpoch(requests);
    earliestRequestAtNotifiers[routeIndex].value = times.isEmpty ? '' : times.first;
    latestRequestAtNotifiers[routeIndex].value = times.isEmpty ? '' : times.last;
    totalRequestsNotifiers[routeIndex].value = requests.length;
  }

  /// Returns a future of list of [Request] and used privately within [getAvailableRoutes] method.
  Future<List<Request>> _getRequestsPerTerminal(
      String routeReference, String terminalReference) async {
    List<Request> terminalRequests = [];
    final DocumentReference routeRef = _db.collection('routes').doc(routeReference);
    final CollectionReference terminalColRef = routeRef.collection('terminals');
    final DocumentReference terminalRef = terminalColRef.doc(terminalReference);
    final CollectionReference requestColRef = terminalRef.collection('requests');
    final QuerySnapshot querySnapshot = await requestColRef.get();
    final List<QueryDocumentSnapshot> requestDocs = querySnapshot.docs;
    for (var requestDoc in requestDocs) {
      terminalRequests.add(Request(requestTime: requestDoc['request_time']));
    }
    return terminalRequests;
  }

  /// Returns a list of [String] of timestamps and used privately within [getAvailableRoutes]
  /// method.
  List<String> _getAllRequestTimesInMillisecondsSinceEpoch(List<Request> requests) {
    List<int> requestTimes = [];
    List<String> formattedTimes = [];
    for (var request in requests) {
      DateTime dateTime = DateTime.parse(request.requestTime);
      requestTimes.add(dateTime.millisecondsSinceEpoch);
    }
    requestTimes.sort();
    for (var time in requestTimes) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(time);
      String formatter =
          '${dateTime.hour.toString().characters.length == 1 ? dateTime.hour.toString().padLeft(2, '0') : dateTime.hour}:${dateTime.minute.toString().characters.length == 1 ? dateTime.minute.toString().padLeft(2, '0') : dateTime.minute}';
      formattedTimes.add(formatter);
    }
    return formattedTimes;
  }

  /// Returns a future of list of [RouteInfo] and used to build [ExpansionPanel] list of all
  /// available routes.
  Future<List<RouteInfo>> getAvailableRoutes(String stationID) async {
    List<RouteInfo> routeInfo = [];
    List<Terminal> terminals = [];
    List<Request> requests = [];
    List<Request> terminalRequests = [];
    List<String> routeRefs = [];
    List<QueryDocumentSnapshot> stationRouteDocs = [];
    final CollectionReference stationColRef = _db.collection('stations');
    final QuerySnapshot stationQuerySnapshot = await stationColRef.get();
    final List<QueryDocumentSnapshot> stationDocs = stationQuerySnapshot.docs;
    for (var stationDoc in stationDocs) {
      if (stationDoc['station_id'].toString() == stationID) {
        for (var ref in stationDoc['route_list']) {
          routeRefs.add(ref);
        }
      }
    }
    final CollectionReference routeColRef = _db.collection('routes');
    final QuerySnapshot querySnapshot = await routeColRef.get();
    final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;

    for (var element in routeDocs) {
      for (var routeRef in routeRefs) {
        if (element.id == routeRef) {
          stationRouteDocs.add(element);
        }
      }
    }
    for (var stationRouteDoc in stationRouteDocs) {
      final CollectionReference terminalColRef = stationRouteDoc.reference.collection('terminals');
      final QuerySnapshot querySnapshot = await terminalColRef.get();
      final List<QueryDocumentSnapshot> terminalDocs = querySnapshot.docs;

      for (var terminalDoc in terminalDocs) {
        final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
        final QuerySnapshot querySnapshot = await requestColRef.get();
        final List<QueryDocumentSnapshot> requestDocs = querySnapshot.docs;
        terminalRequests = await _getRequestsPerTerminal(stationRouteDoc.id, terminalDoc.id);
        final bool exist = _containsId(terminals, terminalDoc['terminal_id']);
        if (!exist) {
          terminals.add(Terminal(
            terminalID: terminalDoc['terminal_id'],
            terminalName: terminalDoc['terminal_name'],
            terminalLocation: TerminalLocation(
              latitude: terminalDoc['terminal_location']['terminal_latitude'],
              longitude: terminalDoc['terminal_location']['terminal_longitude'],
            ),
            requests: terminalRequests,
          ));
        }
        for (var requestDoc in requestDocs) {
          requests.add(Request(
            requestTime: requestDoc['request_time'],
          ));
        }
      }
      List<String> requestTimes = _getAllRequestTimesInMillisecondsSinceEpoch(requests);
      routeInfo.add(
        RouteInfo(
          routeID: stationRouteDoc['route_id'],
          reference: stationRouteDoc.id,
          fromTerminal: stationRouteDoc['from_terminal'],
          toTerminal: stationRouteDoc['to_terminal'],
          routeTerminals: terminals,
          totalRequests: requests.length,
          latestRequestAt: requestTimes.isEmpty ? '' : requestTimes.last,
          earliestRequestAt: requestTimes.isEmpty ? '' : requestTimes.first,
        ),
      );
    }
    return routeInfo;
  }

  Future<List<String>> getAllStationIDs() async {
    List<String> stationIDs = [];
    final CollectionReference stationColRef = _db.collection('stations');
    final QuerySnapshot querySnapshot = await stationColRef.get();
    final List<QueryDocumentSnapshot> stationDocs = querySnapshot.docs;
    for (var doc in stationDocs) {
      stationIDs.add(doc['station_id'].toString());
    }
    return stationIDs;
  }

  Future<QuerySnapshot> getAllRoutes() async {
    return await _db.collection('routes').get();
  }

  Future<QuerySnapshot> getAllDrivers() async {
    return await _db.collection('drivers').get();
  }

  bool _containsId(List<Terminal> terminals, int id) {
    return terminals.any((element) => element.terminalID == id);
  }
}
