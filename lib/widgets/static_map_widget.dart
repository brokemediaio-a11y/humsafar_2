import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/maps_config.dart';
import '../services/directions_service.dart';

/// Static map widget as fallback when interactive map fails
/// Uses Google Static Maps API to show route preview with actual route path
class StaticMapWidget extends StatefulWidget {
  final double? fromLatitude;
  final double? fromLongitude;
  final double? toLatitude;
  final double? toLongitude;
  final String? fromLocation;
  final String? toLocation;
  final double height;

  const StaticMapWidget({
    super.key,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.fromLocation,
    this.toLocation,
    this.height = 200,
  });

  @override
  State<StaticMapWidget> createState() => _StaticMapWidgetState();
}

class _StaticMapWidgetState extends State<StaticMapWidget> {
  List<LatLng>? _routePoints;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(StaticMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch route if locations changed
    if (oldWidget.fromLatitude != widget.fromLatitude ||
        oldWidget.fromLongitude != widget.fromLongitude ||
        oldWidget.toLatitude != widget.toLatitude ||
        oldWidget.toLongitude != widget.toLongitude) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    if (widget.fromLatitude == null ||
        widget.fromLongitude == null ||
        widget.toLatitude == null ||
        widget.toLongitude == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final routePoints = await DirectionsService.getRoute(
        fromLat: widget.fromLatitude!,
        fromLng: widget.fromLongitude!,
        toLat: widget.toLatitude!,
        toLng: widget.toLongitude!,
      );

      if (mounted) {
        setState(() {
          _routePoints = routePoints;
          _isLoadingRoute = false;
        });
        if (routePoints != null && routePoints.isNotEmpty) {
          debugPrint('🗺️ Static Map: Successfully fetched ${routePoints.length} route points');
        } else {
          debugPrint('🗺️ Static Map: Route fetch returned null/empty, will use straight line');
        }
      }
    } catch (e) {
      debugPrint('🗺️ Error fetching route for static map: $e');
      if (mounted) {
        setState(() {
          _routePoints = null; // Will use straight line fallback
          _isLoadingRoute = false;
        });
      }
    }
  }

  String _getStaticMapUrl() {
    if (widget.fromLatitude == null ||
        widget.fromLongitude == null ||
        widget.toLatitude == null ||
        widget.toLongitude == null) {
      return '';
    }

    // Build path for route - use actual route points if available
    String path;
    if (_routePoints != null && _routePoints!.isNotEmpty) {
      // Use actual route points from Directions API
      // Static Maps API has a URL length limit, so we may need to simplify the path
      // For very long routes, we'll sample points to stay within limits
      List<LatLng> pathPoints = _routePoints!;
      
      // If route has too many points, sample them (keep first, last, and evenly spaced middle points)
      if (pathPoints.length > 100) {
        final sampled = <LatLng>[];
        sampled.add(pathPoints.first); // Always include start
        final step = (pathPoints.length / 50).ceil(); // Sample ~50 points
        for (int i = step; i < pathPoints.length - step; i += step) {
          sampled.add(pathPoints[i]);
        }
        sampled.add(pathPoints.last); // Always include end
        pathPoints = sampled;
      }
      
      final pathString = pathPoints
          .map((point) => '${point.latitude},${point.longitude}')
          .join('|');
      path = 'path=color:0x49977a|weight:4|$pathString';
    } else {
      // Fallback to straight line only if route fetch failed
      path = 'path=color:0x49977a|weight:4|${widget.fromLatitude},${widget.fromLongitude}|${widget.toLatitude},${widget.toLongitude}';
    }
    
    // Build markers
    final markers = 'markers=color:green|label:A|${widget.fromLatitude},${widget.fromLongitude}&markers=color:red|label:B|${widget.toLatitude},${widget.toLongitude}';
    
    // Calculate center and zoom
    final centerLat = (widget.fromLatitude! + widget.toLatitude!) / 2;
    final centerLng = (widget.fromLongitude! + widget.toLongitude!) / 2;
    
    // Static Maps API max size is 640x640, so cap the dimensions
    final mapWidth = 600;
    final mapHeight = (widget.height * 2).toInt().clamp(200, 640); // Clamp between 200 and 640
    
    // Build URL with proper encoding
    final url = 'https://maps.googleapis.com/maps/api/staticmap?'
        'size=${mapWidth}x$mapHeight&'
        'zoom=12&'
        'center=$centerLat,$centerLng&'
        '$path&'
        '$markers&'
        'key=${MapsConfig.apiKey}';
    
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final mapUrl = _getStaticMapUrl();
    
    if (mapUrl.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: Text(
            'Map unavailable',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Show loading while fetching route
    if (_isLoadingRoute) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF49977a)),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          mapUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: widget.height,
              color: Colors.grey.shade100,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF49977a)),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Log error for debugging
            debugPrint('🗺️ Static Map Error: $error');
            debugPrint('🗺️ Map URL: $mapUrl');
            
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, color: Colors.grey.shade400, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Map preview unavailable',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enable Maps Static API in Google Cloud',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.fromLocation != null && widget.toLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${widget.fromLocation} → ${widget.toLocation}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

