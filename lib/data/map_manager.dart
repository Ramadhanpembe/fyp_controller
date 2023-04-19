import 'dart:convert';

import 'package:fyp_controller/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapManager {
  static Future<List<LatLng>> calculateRoute(
      {required LatLng startPosition, required LatLng endPosition}) async {
    List<LatLng> coordinates = [];
    String routingUrl =
        '$tomtomRoutingUrl/1/calculateRoute/${startPosition.latitude},${startPosition.longitude}:${endPosition.latitude},${endPosition.longitude}/json?key=$apiKey';
    http.Response response = await http.get(Uri.parse(routingUrl));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> route = data['routes'][0]['legs'][0]['points'];
      for (var point in route) {
        coordinates.add(LatLng(point['latitude'], point['longitude']));
      }
    }
    return coordinates;
  }
}
