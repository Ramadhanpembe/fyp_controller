import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_controller/data/firestore_manager.dart';
import 'package:fyp_controller/models/request.dart';
import 'package:fyp_controller/models/route_info.dart';
import 'package:fyp_controller/models/terminal.dart';
import 'package:fyp_controller/utils/constants.dart';
import 'package:latlong2/latlong.dart';

import '../data/resources.dart';
import '../models/terminal_location.dart';
import '../notifiers/autorelease_button_notifier.dart';
import '../widgets/autorelease_button.dart';
import '../widgets/controller_logo.dart';
import '../widgets/footer.dart';
import '../widgets/map_container.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool isFocused = false;
  bool isHovered = false;
  final listOfTerminalsNotifier = ValueNotifier<List<Terminal>>([]);
  final listOfRoutesNotifier = ValueNotifier<List<RouteInfo>>([]);
  final totalRequestsNotifier = ValueNotifier<int>(0);
  final earliestRequestAtNotifier = ValueNotifier<String>('');
  final latestRequestAtNotifier = ValueNotifier<String>('');

  //*------------------------------------------------------------------*//
  late final MapController _mapController;
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    firestoreManager = FirestoreManager();
    _stream = firestoreManager.listenOnRouteCollectionUpdates();
    _mapController = MapController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final officeLocation = LatLng(-6.7789659, 39.2525232);
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: width <= 1000 ? 2 : 1,
              child: Scaffold(
                appBar: AppBar(
                  title: const ControllerLogo(),
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
                          child: Text('Loading...'),
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
              flex: width <= 1000 ? 2 : 3,
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
      },
    );
  }

  ValueListenableBuilder _buildExpansionPanels() {
    return ValueListenableBuilder(
      valueListenable: listOfRoutesNotifier,
      builder: (_, routes, __) {
        return ExpansionPanelList(
          expansionCallback: (index, isExpanded) {
            setState(() {
              routes[index].isExpanded = !isExpanded;
            });
          },
          children: routes.map<ExpansionPanel>((RouteInfo info) {
            return ExpansionPanel(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ExpansionTile(
                  title: Text('${info.fromTerminal} - ${info.toTerminal}'),
                  leading: ValueListenableBuilder(
                      valueListenable: totalRequestsNotifier,
                      builder: (_, totalRequests, __) {
                        return _buildCircleAvatar(totalRequests);
                      }),
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
                        child: _buildTerminals(),
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
      },
    );
  }

  Column _buildTrailing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: latestRequestAtNotifier,
          builder: (_, latestRequest, __) {
            return Text(
              'Latest: $latestRequest',
              style: kTrailingStyle,
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: earliestRequestAtNotifier,
          builder: (_, earliestRequest, __) {
            return Text(
              'Earliest: $earliestRequest',
              style: kTrailingStyle,
            );
          },
        ),
      ],
    );
  }

  CircleAvatar _buildCircleAvatar(int totalRequests) {
    return CircleAvatar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      child: Text(totalRequests.toString()),
    );
  }

  ValueListenableBuilder _buildTerminals() {
    List<Row> rows = [];
    return ValueListenableBuilder(
      valueListenable: listOfTerminalsNotifier,
      builder: (_, listOfTerminals, __) {
        for (var terminal in listOfTerminals) {
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
                child: Text(
                  terminal.requests.length.toString(),
                  style: kTerminalStyle,
                ),
              ),
            ],
          );
          rows.add(row);
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
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

  void _loadUI(AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
    List<RouteInfo> routes = [];
    List<Terminal> terminals = [];
    List<Request> requests = [];
    List<Request> terminalRequests = [];
    final QuerySnapshot querySnapshot = snapshot.data!;
    final List<QueryDocumentSnapshot> routeDocs = querySnapshot.docs;

    for (var routeDoc in routeDocs) {
      final CollectionReference terminalColRef = routeDoc.reference.collection('terminals');
      terminalColRef.snapshots().listen((terminalSnapshot) {
        final List<QueryDocumentSnapshot> terminalDocs = terminalSnapshot.docs;
        for (var terminalDoc in terminalDocs) {
          terminals.add(_getTerminal(terminalDoc));
          listOfTerminalsNotifier.value = terminals;
          final CollectionReference requestColRef = terminalDoc.reference.collection('requests');
          requestColRef.snapshots().listen((requestSnapshot) {
            final List<QueryDocumentSnapshot> requestDocs = requestSnapshot.docs;
            for (var requestDoc in requestDocs) {
              requests.add(Request(requestTime: requestDoc['request_time']));
              totalRequestsNotifier.value = requests.length;
            }
            final times = _getAllRequestTimesInMillisecondsSinceEpoch(requests);
            earliestRequestAtNotifier.value = times.first;
            latestRequestAtNotifier.value = times.last;
          });
        }
      });
      routes.add(_getRouteInfo(routeDoc));
      listOfRoutesNotifier.value = routes;
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
