class DriverLocation {
  const DriverLocation(
      {required this.latitude, required this.longitude, this.accuracy, this.speed});
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
}
