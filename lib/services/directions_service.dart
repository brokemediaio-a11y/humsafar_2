import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/maps_config.dart';

/// Service to fetch route directions from Google Directions API
class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get route between two points
  /// Returns list of LatLng points for the route polyline
  static Future<List<LatLng>?> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?origin=$fromLat,$fromLng&destination=$toLat,$toLng&key=${MapsConfig.apiKey}',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Directions API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final overviewPolyline = route['overview_polyline'];
          final encodedPolyline = overviewPolyline['points'];
          
          // Decode polyline to get list of LatLng points
          final points = _decodePolyline(encodedPolyline);
          debugPrint('🗺️ Directions API: Successfully decoded ${points.length} route points');
          return points;
        } else {
          // If API fails, log the error
          debugPrint('🗺️ Directions API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        debugPrint('🗺️ Directions API HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('🗺️ Directions API Exception: $e');
      return null;
    }
  }

  /// Decode Google's encoded polyline string to list of LatLng
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

