import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_controller/data/firestore_manager.dart';
import 'package:fyp_controller/models/route_info.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';
import 'package:fyp_controller/utils/constants.dart';
import 'package:latlong2/latlong.dart';

import '../data/resources.dart';
import '../widgets/autorelease_button.dart';
import '../widgets/controller_logo.dart';
import '../widgets/footer.dart';
import '../widgets/map_container.dart';

class Test0Page extends StatefulWidget {
  const Test0Page({super.key});

  @override
  State<Test0Page> createState() => _Test0PageState();
}

class _Test0PageState extends State<Test0Page> {
  bool isFocused = false;
  bool isHovered = false;
  late MapController _mapController;
  late final Future<List<RouteInfo>> _routeInfo;

  @override
  void initState() {
    firestoreManager = FirestoreManager();
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
              child: _buildExpansionPanels(),
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
                      leading: _buildCircleAvatar(info),
                      trailing: _buildTrailing(info),
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

  Column _buildTrailing(RouteInfo info) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest: ${info.latestRequestAt!}',
          style: kTrailingStyle,
        ),
        Text(
          'Earliest: ${info.earliestRequestAt!}',
          style: kTrailingStyle,
        ),
      ],
    );
  }

  CircleAvatar _buildCircleAvatar(RouteInfo info) {
    return CircleAvatar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      child: Text(info.totalRequests.toString()),
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
            child: Text(
              terminal.requests.length.toString(),
              style: kTerminalStyle,
            ),
          ),
        ],
      );
      rows.add(row);
    }
    return rows;
  }
}
