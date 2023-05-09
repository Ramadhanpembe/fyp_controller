import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_controller/data/location_manager.dart';
import 'package:fyp_controller/data/map_manager.dart';
import 'package:fyp_controller/models/route_info.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';
import 'package:fyp_controller/utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/resources.dart';
import '../models/driver_info.dart';
import '../widgets/autorelease_button.dart';
import '../widgets/controller_logo.dart';
import '../widgets/footer.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/map_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.stationID});

  final String stationID;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isFocused = false;
  bool isHovered = false;
  late final MapController _mapController;
  late final Stream<QuerySnapshot> _stream;
  late final Future<List<RouteInfo>> _routeInfo;
  final fromTerminalLocation = LatLng(-6.7783608, 39.2445853);
  final toTerminalLocation = LatLng(-6.7877519, 39.2138601);
  late final Position stationPosition;
  Map<String, dynamic> notified = {};
  String phone = '';

  Future<void> _toFirestore() async {
    List<RouteInfo> toFirestore = await firestoreManager.getAvailableRoutes(widget.stationID);
    totalRequestsNotifiers = List.generate(toFirestore.length, (index) => ValueNotifier<int>(0));
    earliestRequestAtNotifiers =
        List.generate(toFirestore.length, (index) => ValueNotifier<String>(''));
    latestRequestAtNotifiers =
        List.generate(toFirestore.length, (index) => ValueNotifier<String>(''));
    stationPosition = await Geolocator.getCurrentPosition();
  }

  void _initNotifiers() async {
    await _toFirestore();
  }

  @override
  void initState() {
    _initNotifiers();
    mapManager = MapManager();

    _stream = firestoreManager.listenOnRouteCollectionUpdates();
    _routeInfo = firestoreManager.getAvailableRoutes(widget.stationID);
    _mapController = MapController();
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      firestoreManager.decrement();
      notified = await autoNotifyDriver();
      DriverInfo driverInfo = DriverInfo(
          username: '',
          phone: '',
          fromTerminal: '',
          toTerminal: '',
          latitude: 0.0,
          longitude: 0.0,
          timestamp: '');
      final DriverInfo info = notified['info'] ?? driverInfo;
      if (info.phone != phone) {
        await firestoreManager.sendNotification(info.phone);
        phone = info.phone;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Scaffold(
            appBar: AppBar(
              leading: const ControllerLogo(),
              leadingWidth: MediaQuery.of(context).size.width * 0.15,
              toolbarHeight: 70.0,
              actions: [
                StatefulBuilder(
                  builder: (context, StateSetter state) {
                    return AutoreleaseButton(
                      isFocused: isHovered,
                      onHover: (val) {
                        state(() => (val ?? false) ? isHovered = true : isHovered = false);
                      },
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: StreamBuilder(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.data == null) {
                    return const LoadingIndicator();
                  }
                  return _buildExpansionPanels(snapshot);
                },
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MapContainer(
                mapController: _mapController,
                fromTerminalLocation: fromTerminalLocation,
                toTerminalLocation: toTerminalLocation,
                routeInfo: routeInfo,
              ),
              StatefulBuilder(
                builder: (context, state) {
                  return Footer(
                    isFocused: isFocused,
                    onHover: (focus) {
                      state(() => focus ? isFocused = true : isFocused = false);
                    },
                  );
                },
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionPanels(AsyncSnapshot<QuerySnapshot<Object?>> routeSnapshot) {
    return FutureBuilder(
        future: _routeInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
            return const LoadingIndicator();
          }

          final QuerySnapshot querySnapshot = routeSnapshot.data!;
          List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;
          routeInfo = snapshot.data!;
          return ExpansionPanelList(
            expansionCallback: (index, isExpanded) {
              setState(() {
                routeInfo[index].isExpanded = !isExpanded;
              });
            },
            children: routeInfo.map<ExpansionPanel>((RouteInfo info) {
              Timer.periodic(
                  const Duration(seconds: 1),
                  (timer) =>
                      firestoreManager.listenForAllRouteRequestUpdates(info.reference, routeInfo));
              for (var routeDoc in routeDocs) {
                if (routeDoc.id == info.reference) {
                  final CollectionReference terminalColRef =
                      routeDoc.reference.collection('terminals');
                  return ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ExpansionTile(
                        title: Text('${info.fromTerminal} - ${info.toTerminal}'),
                        leading: _buildCircleAvatar(info.reference, routeInfo),
                        trailing: _buildTrailing(info.reference, routeInfo),
                      );
                    },
                    body: Column(
                      children: [
                        SizedBox(
                          height: 200.0,
                          width: MediaQuery.of(context).size.width * 0.18,
                          child: Center(
                            child: SingleChildScrollView(
                              child: StreamBuilder(
                                stream: terminalColRef.snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting ||
                                      snapshot.data == null) {
                                    return const LoadingIndicator();
                                  }
                                  final QuerySnapshot terminalQuerySnapshot = snapshot.data!;
                                  List<QueryDocumentSnapshot> terminalDocs =
                                      terminalQuerySnapshot.docs;
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _buildTerminals(info, terminalDocs),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        ValueListenableBuilder<ReleaseButtonState>(
                          valueListenable: autoreleaseButtonNotifier,
                          builder: (_, val, __) {
                            if (val == ReleaseButtonState.manualRelease) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _displayDriverList(info);
                                    },
                                    child: const Text('RELEASE BUS'),
                                  ),
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ],
                    ),
                    isExpanded: info.isExpanded,
                  );
                }
              }
              return ExpansionPanel(
                headerBuilder: (context, isExpanded) {
                  return const Text('');
                },
                body: const Text(''),
              );
            }).toList(),
          );
        });
  }

  Column _buildTrailing(String routeID, List<RouteInfo> routeInfo) {
    final int routeIndex = routeInfo.indexWhere((element) => element.reference == routeID);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: latestRequestAtNotifiers[routeIndex],
          builder: (_, latestRequestAt, __) {
            return Text(
              'Latest: $latestRequestAt',
              style: kTrailingStyle,
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: earliestRequestAtNotifiers[routeIndex],
          builder: (_, earliestRequestAt, __) {
            return Text(
              'Earliest: $earliestRequestAt',
              style: kTrailingStyle,
            );
          },
        ),
      ],
    );
  }

  ValueListenableBuilder _buildCircleAvatar(String routeID, List<RouteInfo> routeInfo) {
    final int routeIndex = routeInfo.indexWhere((element) => element.reference == routeID);
    return ValueListenableBuilder(
      valueListenable: totalRequestsNotifiers[routeIndex],
      builder: (_, totalRequests, __) {
        return CircleAvatar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          child: Text(totalRequests.toString()),
        );
      },
    );
  }

  List<Row> _buildTerminals(RouteInfo info, List<QueryDocumentSnapshot> terminalDocs) {
    List<Row> rows = [];
    for (var terminal in info.routeTerminals) {
      for (var terminalDoc in terminalDocs) {
        if (terminal.terminalID == terminalDoc['terminal_id']) {
          rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(terminal.terminalName, style: kTerminalStyle),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0, right: 16.0),
                child: StreamBuilder(
                  stream: terminalDoc.reference.collection('requests').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        snapshot.data == null) {
                      return Container();
                    }
                    final requestsQuerySnapshot = snapshot.data!;

                    return Text(
                      '${requestsQuerySnapshot.docs.length}',
                      style: kTerminalStyle,
                    );
                  },
                ),
              ),
            ],
          ));
        }
      }
    }
    return rows;
  }

  void _displayDriverList(RouteInfo info) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Choose driver to release to:',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            content: SizedBox(
              width: 270.0,
              height: 250.0,
              child: FutureBuilder(
                future: firestoreManager.getDriverInfo(info),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Text('Loading...'),
                    );
                  }
                  if (snapshot.data == null) {
                    return const Center(
                      child: Text('Data is null!'),
                    );
                  }
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Empty'),
                    );
                  }
                  List<DriverInfo> driverInfo = snapshot.data!;
                  return ListView.builder(
                    itemCount: driverInfo.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          child: Text(
                            driverInfo[index].username.characters.first.toUpperCase(),
                            style: const TextStyle(fontSize: 22.0),
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        title: Text(driverInfo[index].username),
                        subtitle: Text(driverInfo[index].phone),
                        onTap: () async {
                          await firestoreManager.sendNotification(driverInfo[index].phone);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Center(child: Text('The driver has been notified!!')),
                              ),
                            );
                          }
                          await _checkManualDriverMotion(driverInfo[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );
        });
  }

  Future<void> _checkManualDriverMotion(DriverInfo driverInfo) async {
    final Map<String, dynamic> initialPosition =
        await firestoreManager.getDriverCurrentLocation(driverInfo);
    final LatLng latLng1 =
        LatLng(initialPosition['latitude'] ?? 0.0, initialPosition['longitude'] ?? 0.0);
    Map<String, dynamic> finalPosition = {};
    bool isMoving = await Future.delayed(const Duration(minutes: 2), () async {
      bool moving = true;
      finalPosition = await firestoreManager.getDriverCurrentLocation(driverInfo);
      final LatLng latLng2 =
          LatLng(finalPosition['latitude'] ?? 0.0, finalPosition['longitude'] ?? 0.0);
      final double travelledDistance =
          LocationManager.distanceBetween(latLng1: latLng1, latLng2: latLng2);
      if (travelledDistance < 100) {
        moving = false;
        if (mounted) {
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text(
                    'Driver ${driverInfo.username} is not moving! Please choose another driver!',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16.0),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OKAY'),
                    ),
                  ],
                );
              });
        }
      }
      return moving;
    });
    log('-------------IsDriverMoving?: $isMoving');
    driverIsMoving = isMoving;
    driverPhone = driverInfo.phone;
  }

  // Future<void> _checkAutoDriverMotion(DriverInfo driverInfo) async {
  //   final Map<String, dynamic> initialPosition =
  //       await firestoreManager.getDriverCurrentLocation(driverInfo);
  //   final LatLng latLng1 =
  //       LatLng(initialPosition['latitude'] ?? 0.0, initialPosition['longitude'] ?? 0.0);
  //   Map<String, dynamic> finalPosition = {};
  //   bool isMoving = await Future.delayed(const Duration(minutes: 2), () async {
  //     bool moving = true;
  //     finalPosition = await firestoreManager.getDriverCurrentLocation(driverInfo);
  //     final LatLng latLng2 =
  //         LatLng(finalPosition['latitude'] ?? 0.0, finalPosition['longitude'] ?? 0.0);
  //     final double travelledDistance =
  //         LocationManager.distanceBetween(latLng1: latLng1, latLng2: latLng2);
  //     if (travelledDistance < 100) {
  //       moving = false;
  //     }
  //     return moving;
  //   });
  //   log('-------------IsDriverMoving?: $isMoving');
  //   driverIsMoving = isMoving;
  //   driverPhone = driverInfo.phone;
  // }

  Future<Map<String, dynamic>> autoNotifyDriver() async {
    if (!autoReleaseOnNotifier.value) return {};
    for (int i = 0; i < totalRequestsNotifiers.length; i++) {
      if (totalRequestsNotifiers[i].value >= 20) {
        final QuerySnapshot routeQuerySnapshot = await firestoreManager.getAllRoutes();
        final List<QueryDocumentSnapshot> routeDocs = routeQuerySnapshot.docs;
        final QueryDocumentSnapshot myRouteDoc = routeDocs.elementAt(i);
        final QuerySnapshot driverQuerySnapshot = await firestoreManager.getAllDrivers();
        final List<QueryDocumentSnapshot> driverDocs = driverQuerySnapshot.docs;
        final List<QueryDocumentSnapshot> requiredDriverDocs = [];
        for (var driverDoc in driverDocs) {
          if (driverDoc['route']['from_terminal'] == myRouteDoc['from_terminal'] &&
              driverDoc['route']['to_terminal'] == myRouteDoc['to_terminal']) {
            requiredDriverDocs.add(driverDoc);
          }
        }
        List<QueryDocumentSnapshot> inStationDrivers = [];
        if (isPermissionGranted) {
          final stationPosition = await Geolocator.getCurrentPosition();
          final stationLatLng = LatLng(stationPosition.latitude, stationPosition.longitude);
          for (var driverDoc in requiredDriverDocs) {
            final driverLatLng =
                LatLng(driverDoc['location']['latitude'], driverDoc['location']['longitude']);
            final double distanceBetween =
                LocationManager.distanceBetween(latLng1: stationLatLng, latLng2: driverLatLng);
            if (distanceBetween <= 9000.0) inStationDrivers.add(driverDoc);
          }
        }
        List<int> timestamps = [];
        for (var driver in inStationDrivers) {
          final String? timestamp = driver['location']['timestamp'];
          timestamps.add(DateTime.parse(timestamp ?? '2023-05-04').millisecondsSinceEpoch);
        }
        timestamps.sort();
        final int timestampOfRequiredDriver = timestamps.isEmpty ? 0 : timestamps.first;
        for (var driver in inStationDrivers) {
          final String timestamps = driver['location']['timestamp'];
          if (DateTime.parse(timestamps).millisecondsSinceEpoch == timestampOfRequiredDriver) {
            return <String, dynamic>{
              'bool': true,
              'info': DriverInfo(
                username: driver['username'],
                phone: driver['login']['phone'],
                fromTerminal: driver['route']['from_terminal'],
                toTerminal: driver['route']['to_terminal'],
                latitude: driver['location']['latitude'],
                longitude: driver['location']['longitude'],
                timestamp: driver['location']['timestamp'],
              ),
            };
          }
        }
      }
    }
    return {};
  }
}
