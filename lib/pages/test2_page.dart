import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_controller/data/firestore_manager.dart';
import 'package:fyp_controller/models/route_info.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';
import 'package:fyp_controller/utils/constants.dart';
import 'package:latlong2/latlong.dart';

import '../data/resources.dart';
import '../models/request.dart';
import '../models/terminal.dart';
import '../models/terminal_location.dart';
import '../widgets/autorelease_button.dart';
import '../widgets/controller_logo.dart';
import '../widgets/footer.dart';
import '../widgets/map_container.dart';

class Test2Page extends StatefulWidget {
  const Test2Page({super.key});

  @override
  State<Test2Page> createState() => _Test2PageState();
}

class _Test2PageState extends State<Test2Page> {
  bool isFocused = false;
  bool isHovered = false;
  final listOfRoutesNotifier = ValueNotifier<List<RouteInfo>>([]);
  final terminalRequestsNotifier = ValueNotifier<int>(0);
  final totalRequestsNotifier = ValueNotifier<int>(0);
  final earliestRequestAtNotifier = ValueNotifier<String>('');
  final latestRequestAtNotifier = ValueNotifier<String>('');
  late final MapController _mapController;
  late final Stream<QuerySnapshot> _stream;
  late final Future<List<RouteInfo>> _routeInfo;

  @override
  void initState() {
    firestoreManager = FirestoreManager();
    _stream = firestoreManager.listenOnRouteCollectionUpdates();
    _routeInfo = firestoreManager.getAvailableRoutes();
    _mapController = MapController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final officeLocation = LatLng(-6.7789659, 39.2525232);
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
                AutoreleaseButton(
                  isFocused: isHovered,
                  onHover: (val) {
                    setState(() {
                      (val ?? false) ? isHovered = true : isHovered = false;
                    });
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: StreamBuilder(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.data == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: SizedBox(
                          width: 32.0,
                          height: 32.0,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }
                  _loadUI(snapshot);
                  return _buildExpansionPanels();
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
              MapContainer(mapController: _mapController, location: officeLocation),
              Footer(
                isFocused: isFocused,
                onHover: (focus) {
                  setState(() {
                    focus ? isFocused = true : isFocused = false;
                  });
                },
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionPanels() {
    return FutureBuilder(
        future: _routeInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  width: 32.0,
                  height: 32.0,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            List<RouteInfo> routeInfo = snapshot.data!;
            return ExpansionPanelList(
              expansionCallback: (index, isExpanded) {
                setState(() {
                  routeInfo[index].isExpanded = !isExpanded;
                });
              },
              children: routeInfo.map<ExpansionPanel>((RouteInfo info) {
                return ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ExpansionTile(
                      title: Text('${info.fromTerminal} - ${info.toTerminal}'),
                      leading: _buildCircleAvatar(),
                      trailing: _buildTrailing(),
                    );
                  },
                  body: Column(
                    children: [
                      SizedBox(
                        height: 200.0,
                        width: MediaQuery.of(context).size.width * 0.18,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildTerminals(info),
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
                                  onPressed: () {},
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
              }).toList(),
            );
          }
          return const Center(
            child: Text('Mhh! Something\'s wrong'),
          );
        });
  }

  Column _buildTrailing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: latestRequestAtNotifier,
          builder: (_, latestRequestAt, __) {
            return Text(
              'Latest: $latestRequestAt',
              style: kTrailingStyle,
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: earliestRequestAtNotifier,
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

  ValueListenableBuilder<int> _buildCircleAvatar() {
    return ValueListenableBuilder(
      valueListenable: totalRequestsNotifier,
      builder: (_, totalRequests, __) {
        return CircleAvatar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          child: Text(totalRequests.toString()),
        );
      },
    );
  }

  List<Row> _buildTerminals(RouteInfo info) {
    List<Row> rows = [];
    for (var terminal in info.routeTerminals) {
      Row row = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(terminal.terminalName, style: kTerminalStyle),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, right: 16.0),
            child: ValueListenableBuilder(
              valueListenable: terminalRequestsNotifier,
              builder: (_, allRequests, __) {
                return Text(
                  allRequests.toString(),
                  style: kTerminalStyle,
                );
                return Container();
              },
            ),
          ),
        ],
      );
      rows.add(row);
    }
    return rows;
  }

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

  void _loadUI(AsyncSnapshot<QuerySnapshot<Object?>> snapshot) async {
    List<Request> requests = [];
    List<int> integers = [];
    final QuerySnapshot querySnapshot = snapshot.data!;
    final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;

    for (var routeDoc in routeDocs) {
      final CollectionReference terminalColRef = routeDoc.reference.collection('terminals');
      terminalColRef.snapshots().listen((terminalSnapshot) {
        final List<QueryDocumentSnapshot> terminalDocs = terminalSnapshot.docs;
        for (var terminalDoc in terminalDocs) {
          final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
          requestColRef.snapshots().listen((requestSnapshot) {
            final List<QueryDocumentSnapshot> requestDocs = requestSnapshot.docs;
            for (var requestDoc in requestDocs) {
              requests.add(Request(requestTime: requestDoc['request_time']));
              totalRequestsNotifier.value = requests.length;
            }
            integers.add(requestDocs.length);
            final times = _getAllRequestTimesInMillisecondsSinceEpoch(requests);
            earliestRequestAtNotifier.value = times.first;
            latestRequestAtNotifier.value = times.last;
          });
        }
      });
    }
  }

  RouteInfo _getRouteInfo(QueryDocumentSnapshot routeDoc) {
    return RouteInfo(
      reference: routeDoc.id,
      fromTerminal: routeDoc['from_terminal'],
      toTerminal: routeDoc['to_terminal'],
      routeTerminals: [],
    );
  }

  Terminal _getTerminal(QueryDocumentSnapshot terminalDoc) {
    final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
    requestColRef.snapshots().listen((querySnapshot) {
      final List<QueryDocumentSnapshot> requestDocs = querySnapshot.docs;
      List<Request> requests = [];
      for (var requestDoc in requestDocs) {
        requests.add(Request(
          requestTime: requestDoc['request_time'],
        ));
      }
    });
    return Terminal(
      terminalID: terminalDoc['terminal_id'],
      terminalName: terminalDoc['terminal_name'],
      terminalLocation: TerminalLocation(
        latitude: terminalDoc['terminal_location']['terminal_latitude'],
        longitude: terminalDoc['terminal_location']['terminal_longitude'],
      ),
      requests: [],
    );
  }
}
