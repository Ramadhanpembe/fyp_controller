import 'package:fyp_controller/models/request.dart';
import 'package:fyp_controller/models/terminal_location.dart';

class Terminal {
  const Terminal(
      {required this.terminalID,
      required this.terminalName,
      required this.requests,
      required this.terminalLocation});
  final int terminalID;
  final String terminalName;
  final TerminalLocation terminalLocation;
  final List<Request> requests;
}
