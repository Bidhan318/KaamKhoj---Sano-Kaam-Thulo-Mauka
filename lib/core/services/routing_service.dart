// lib/core/services/routing_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  /// Fetches a driving route between two points using the public OSRM API.
  /// Returns a list of LatLng points that can be drawn as a Polyline.
  /// If the API fails, it gracefully falls back to a straight line.
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    // OSRM expects coordinates in lon,lat format
    final String url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          // Convert from [lon, lat] back to LatLng
          return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
      }
    } catch (e) {
      // Ignore and fallback
    }
    
    // Fallback to straight line if API fails or times out
    return [start, end];
  }
}
