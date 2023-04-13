import 'package:fyp_controller/models/terminal_location.dart';

import '../models/route_info.dart';
import '../models/terminal.dart';

/// Do not delete this file yet as it will be used to develop the adminPanel
const _location = TerminalLocation(latitude: 0.00000, longitude: 0.00000000);

// sample data commented
RouteInfo route = RouteInfo(
  fromTerminal: 'M/MBUSHO',
  toTerminal: 'SIMU2000',
  routeTerminals: [
    const Terminal(
        terminalID: 1, terminalName: 'Sayansi', terminalLocation: _location, requests: []),
    const Terminal(
        terminalID: 2, terminalName: 'Bamaga', terminalLocation: _location, requests: []),
    const Terminal(terminalID: 3, terminalName: 'ITV', terminalLocation: _location, requests: []),
    const Terminal(
        terminalID: 4, terminalName: 'Mwenge', terminalLocation: _location, requests: []),
    const Terminal(
        terminalID: 5, terminalName: 'Mpakani', terminalLocation: _location, requests: []),
    const Terminal(
        terminalID: 6, terminalName: 'Lifungira', terminalLocation: _location, requests: []),
  ],
);

// List<RouteInfo> routes = List.generate(10, (index) => route, growable: true);
