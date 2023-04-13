import 'package:fyp_controller/models/terminal.dart';

class RouteInfo {
  RouteInfo({
    this.reference = 'undefined',
    required this.fromTerminal,
    required this.toTerminal,
    required this.routeTerminals,
    this.latestRequestAt = '00:00',
    this.earliestRequestAt = '00:00',
    this.totalRequests = 0,
    this.isExpanded = false,
  });
  String reference;
  String fromTerminal;
  String toTerminal;
  String? earliestRequestAt;
  String? latestRequestAt;
  int? totalRequests;
  List<Terminal> routeTerminals;
  bool isExpanded;
}
