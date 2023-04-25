import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_controller/models/request.dart';
import 'package:fyp_controller/models/route_info.dart';
import 'package:fyp_controller/models/terminal_location.dart';
import 'package:latlong2/latlong.dart';

import '../models/driver_info.dart';
import '../models/terminal.dart';
import '../utils/data.dart';

class FirestoreManager {
  /// Declares firestore databases.
  late final FirebaseFirestore _db;

  /// Notifies about the total requests per route.
  /// It used to display the value on the [CircleAvatar] of each route
  late final ValueNotifier totalRequestsNotifier;
  FirestoreManager() {
    _init();
  }

  /// Initializes firestore database and the [totalRequestsNotifier].
  void _init() {
    _db = FirebaseFirestore.instance;
    totalRequestsNotifier = ValueNotifier<int>(0);
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
        };
      }
    }
    return {};
  }

  @Deprecated(
      '[locations] collection will be deleted from the database since all driver locations are map objects within the driver collection. This method is asynchronous and is undesired, [Stream] will need to be returned in order to get the live location of each driver.')
  Future<List<LatLng>> getExistingDriverLocations() async {
    List<LatLng> positions = [];
    await _db.collection('locations').get().then((querySnapshot) {
      for (var docSnapshot in querySnapshot.docs) {
        positions.add(LatLng(docSnapshot['latitude'], docSnapshot['longitude']));
      }
    });
    return positions;
  }

  /// The return of this method should be listen inside [StreamBuilder] in order to get the
  /// real-time driver locations updates.
  Stream<QuerySnapshot> listenOnDriverLocationUpdates() {
    return _db.collection('drivers').snapshots();
  }

  @Deprecated(
      'This method return future from the locations table. [Future] is undesired for the real time updates and [locations] collection will finally be deleted.')
  Future<List<LatLng>> getDriverLocationUpdates() async {
    List<LatLng> positions = [];
    List<String> documentIDs = [];
    await _db.collection('locations').get().then((querySnapshot) {
      for (var docSnapshot in querySnapshot.docs) {
        documentIDs.add(docSnapshot.id);
      }
    });
    for (var documentID in documentIDs) {
      _db.collection('locations').doc(documentID).snapshots().listen((docSnapshot) {
        positions.add(LatLng(docSnapshot['latitude'], docSnapshot['longitude']));
      });
    }

    return positions;
  }

  /// The return of this method is called in [StreamBuilder] to update the values of
  /// [earliestRequestAtNotifier], [latestRequestAtNotifier] and [requestsPerTerminal].
  Stream<QuerySnapshot> listenOnRouteCollectionUpdates() {
    final CollectionReference routeColRef = _db.collection('routes');
    return routeColRef.snapshots();
  }

  @Deprecated(
      'This method is not working correctly. It should be avoided where possible. It currently has no usage within the system.')
  Stream<QuerySnapshot> listenOnRequestCollectionUpdates() {
    Stream<QuerySnapshot> requestStream = const Stream.empty();
    final CollectionReference routeColRef = _db.collection('routes');
    final Stream<QuerySnapshot> routeStream = routeColRef.snapshots();

    routeStream.listen((querySnapshot) {
      final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;
      for (var routeDoc in routeDocs) {
        final CollectionReference terminalColRef = routeDoc.reference.collection('terminals');
        final Stream<QuerySnapshot> terminalStream = terminalColRef.snapshots();
        terminalStream.listen((qs) {
          final List<QueryDocumentSnapshot> terminalDocs = qs.docs;
          for (var terminalDoc in terminalDocs) {
            final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
            requestStream = requestColRef.snapshots();
          }
        });
      }
    });
    // return _db.collection('routes').doc(routeRef).collection('terminals').snapshots();
    return requestStream;
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
  void listenForAllRouteRequestUpdates(String routeID) async {
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
    totalRequestsNotifier.value = requests.length;
    // return requests.length;
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
  Future<List<RouteInfo>> getAvailableRoutes() async {
    List<RouteInfo> routeInfo = [];
    List<Terminal> terminals = [];
    List<Request> requests = [];
    List<Request> terminalRequests = [];
    final CollectionReference routeColRef = _db.collection('routes');
    final QuerySnapshot querySnapshot = await routeColRef.get();
    final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;
    for (var routeDoc in routeDocs) {
      final CollectionReference terminalColRef = routeDoc.reference.collection('terminals');
      final QuerySnapshot querySnapshot = await terminalColRef.get();
      final List<QueryDocumentSnapshot> terminalDocs = querySnapshot.docs;

      for (var terminalDoc in terminalDocs) {
        final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
        final QuerySnapshot querySnapshot = await requestColRef.get();
        final List<QueryDocumentSnapshot> requestDocs = querySnapshot.docs;
        terminalRequests = await _getRequestsPerTerminal(routeDoc.id, terminalDoc.id);
        terminals.add(Terminal(
          terminalID: terminalDoc['terminal_id'],
          terminalName: terminalDoc['terminal_name'],
          terminalLocation: TerminalLocation(
            latitude: terminalDoc['terminal_location']['terminal_latitude'],
            longitude: terminalDoc['terminal_location']['terminal_longitude'],
          ),
          requests: terminalRequests,
        ));
        for (var requestDoc in requestDocs) {
          requests.add(Request(
            requestTime: requestDoc['request_time'],
          ));
        }
      }
      List<String> requestTimes = _getAllRequestTimesInMillisecondsSinceEpoch(requests);
      routeInfo.add(RouteInfo(
        reference: routeDoc.id,
        fromTerminal: routeDoc['from_terminal'],
        toTerminal: routeDoc['to_terminal'],
        routeTerminals: terminals,
        totalRequests: requests.length,
        latestRequestAt: requestTimes.last,
        earliestRequestAt: requestTimes.first,
      ));
    }

    return routeInfo;
  }

  // create route to the database
  // Note: this method belongs to the ADMIN PANEL, I placed it here just to add the basic route that I need to display during the signup process
  /// This method belongs to the [AdminPanel] which is yet to be built.
  @Deprecated('This method belongs to the [AdminPanel] which is yet to be built')
  void createRoute({required String routeID}) async {
    final CollectionReference routesColRef = _db.collection('routes');
    final DocumentReference mainDocRef = routesColRef.doc(routeID);
    await mainDocRef.set({
      'from_terminal': route.fromTerminal,
      'to_terminal': route.toTerminal,
    });

    final CollectionReference terminalColRef = mainDocRef.collection('terminals');
    for (var terminal in route.routeTerminals) {
      final DocumentReference terminalDocRef = terminalColRef.doc('@${terminal.terminalName}@');
      terminalDocRef.set({
        'terminal_id': terminal.terminalID,
        'terminal_name': terminal.terminalName,
        'terminal_location': {
          'terminal_latitude': terminal.terminalLocation.latitude,
          'terminal_longitude': terminal.terminalLocation.longitude,
        }
      });
      final CollectionReference requestColRef = terminalDocRef.collection('requests');
      for (var request in terminal.requests) {
        final DocumentReference requestDocRef = requestColRef.doc(
            '@${terminal.terminalName}@${DateTime.now().millisecondsSinceEpoch}@${Random.secure().nextInt(100)}@');
        requestDocRef.set({'request_time': request.requestTime});
      }
    }
  }
}
