import 'package:cloud_firestore/cloud_firestore.dart';

class DriverInfo {
  const DriverInfo({
    required this.username,
    required this.phone,
    required this.fromTerminal,
    required this.toTerminal,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
  final String username;
  final String phone;
  final String fromTerminal;
  final String toTerminal;
  final double latitude;
  final double longitude;
  final Timestamp timestamp;
}
