import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';

/// Optimized map widget with debouncing, lite mode, and proper memory management
/// to prevent ImageReader_JNI buffer exhaustion errors
class OptimizedMapWidget extends StatefulWidget {
  final double? fromLatitude;
  final double? fromLongitude;
  final double? toLatitude;
  final double? toLongitude;
  final String? fromLocation;
  final String? toLocation;
  final double height;
  final bool showControls;
  final String uniqueKey;
  final Function(LatLng)? onTap;
  final Function(GoogleMapController)? onMapCreated;

  const OptimizedMapWidget({
    super.key,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.fromLocation,
    this.toLocation,
    this.height = 200,
    this.showControls = false,
    required this.uniqueKey,
    this.onTap,
    this.onMapCreated,
  });

  @override
  State<OptimizedMapWidget> createState() => _OptimizedMapWidgetState();
}

class _OptimizedMapWidgetState extends State<OptimizedMapWidget>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isInitialized = false;
  bool _isMapReady = false;
  bool _isDisposed = false;
  Timer? _animationDebounceTimer;
  Completer<GoogleMapController>? _mapControllerCompleter;
  int _updateCount = 0;
  bool _isLoadingRoute = false;
  DateTime? _lastUpdateTime;
  static const Duration _minUpdateInterval = Duration(milliseconds: 10000); // 10 seconds minimum between updates
  final bool _useLiteMode = false; // Disable Lite Mode to show routes (polylines don't work in Lite Mode)
  bool _hasShownRoute = false; // Track if route has been shown to prevent re-rendering

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Delay map setup to prevent immediate buffer acquisition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isDisposed) {
            _setupMap();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(OptimizedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (_isDisposed) return;
    
    // Only update if locations actually changed
    final fromChanged = _hasLocationChanged(
      oldWidget.fromLatitude,
      oldWidget.fromLongitude,
      widget.fromLatitude,
      widget.fromLongitude,
    );
    final toChanged = _hasLocationChanged(
      oldWidget.toLatitude,
      oldWidget.toLongitude,
      widget.toLatitude,
      widget.toLongitude,
    );
    
    if (fromChanged || toChanged) {
      // Reset update count and route flag when locations change
      _updateCount = 0;
      _hasShownRoute = false; // Allow route to be fetched again
      // Debounce updates with longer delay
      _animationDebounceTimer?.cancel();
      _animationDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted && _isMapReady && !_isDisposed) {
          _updateMarkersAndPolylines();
        }
      });
    }
  }

  bool _hasLocationChanged(
    double? oldLat,
    double? oldLng,
    double? newLat,
    double? newLng,
  ) {
    if (oldLat == null && newLat == null) return false;
    if (oldLat == null || newLat == null) return true;
    return oldLat != newLat || oldLng != newLng;
  }

  void _setupMap() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Delay updates to prevent buffer exhaustion, but not too long
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_isDisposed && _isMapReady) {
        _updateMarkersAndPolylines();
      }
    });
  }

  Future<void> _updateMarkersAndPolylines() async {
    if (_isDisposed || !mounted) return;
    
    // Prevent multiple simultaneous updates
    if (_isLoadingRoute) return;
    
    // Rate limiting: prevent updates more than once per interval
    final now = DateTime.now();
    if (_lastUpdateTime != null && 
        now.difference(_lastUpdateTime!) < _minUpdateInterval) {
      return; // Skip this update, too soon
    }
    _lastUpdateTime = now;
    
    _updateCount++;
    // Only log first update to reduce spam
    if (_updateCount == 1) {
      debugPrint('🗺️ Updating map with coordinates');
    }
    
    // Clear existing markers and polylines to free memory
    _markers.clear();
    _polylines.clear();

    if (widget.fromLatitude != null && widget.fromLongitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: LatLng(widget.fromLatitude!, widget.fromLongitude!),
          infoWindow: InfoWindow(
            title: widget.fromLocation ?? 'From',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (widget.toLatitude != null && widget.toLongitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: LatLng(widget.toLatitude!, widget.toLongitude!),
          infoWindow: InfoWindow(
            title: widget.toLocation ?? 'To',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (widget.fromLatitude != null &&
        widget.fromLongitude != null &&
        widget.toLatitude != null &&
        widget.toLongitude != null &&
        !_hasShownRoute) { // Only fetch route once
      // Fetch real route from Google Directions API
      _isLoadingRoute = true;
      try {
        final routePoints = await DirectionsService.getRoute(
          fromLat: widget.fromLatitude!,
          fromLng: widget.fromLongitude!,
          toLat: widget.toLatitude!,
          toLng: widget.toLongitude!,
        );
        
        // Use real route if available, otherwise fallback to simple route
        final points = routePoints ?? _generateSimpleRoute(
          LatLng(widget.fromLatitude!, widget.fromLongitude!),
          LatLng(widget.toLatitude!, widget.toLongitude!),
        );
        
        if (points.isNotEmpty && mounted && !_isDisposed) {
          _polylines.clear(); // Clear any existing polylines
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: const Color(0xFF49977a),
              width: 4,
              patterns: [],
              geodesic: true, // Enable geodesic for curved routes
            ),
          );
          _hasShownRoute = true; // Mark route as shown
          
          // Force map update to show route
          if (mounted && !_isDisposed) {
            setState(() {});
          }
        }
      } catch (e) {
        debugPrint('Error fetching route: $e');
        // Fallback to simple route on error
        final routePoints = _generateSimpleRoute(
          LatLng(widget.fromLatitude!, widget.fromLongitude!),
          LatLng(widget.toLatitude!, widget.toLongitude!),
        );
        
        if (mounted && !_isDisposed) {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: const Color(0xFF49977a),
              width: 4,
              patterns: [],
              geodesic: false,
            ),
          );
          _hasShownRoute = true;
          
          // Force map update to show route
          setState(() {});
        }
      } finally {
        _isLoadingRoute = false;
      }
    }

    // Update map to show markers and route - but throttle to prevent buffer exhaustion
    if (mounted && !_isDisposed) {
      _animationDebounceTimer?.cancel();
      _animationDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && !_isDisposed) {
          // Only update if we have markers or polylines to show
          if (_markers.isNotEmpty || _polylines.isNotEmpty) {
            setState(() {});
          }
        }
      });
    }
  }

  // Generate simple route to reduce memory usage
  List<LatLng> _generateSimpleRoute(LatLng start, LatLng end) {
    final points = <LatLng>[];
    points.add(start);

    // Calculate distance
    final distance = _calculateDistance(start.latitude, start.longitude, end.latitude, end.longitude);
    
    // Only add intermediate points for very long routes to save memory
    if (distance > 20) { // Only for routes > 20km
      final midLat = (start.latitude + end.latitude) / 2;
      final midLng = (start.longitude + end.longitude) / 2;
      points.add(LatLng(midLat, midLng));
    }

    points.add(end);
    return points;
  }

  // Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  void _animateCameraToBounds() {
    if (_isDisposed ||
        widget.fromLatitude == null ||
        widget.fromLongitude == null ||
        widget.toLatitude == null ||
        widget.toLongitude == null ||
        _mapController == null ||
        !_isMapReady) {
      return;
    }

    // Cancel any pending animations
    _animationDebounceTimer?.cancel();

    // Debounce camera animation with longer delay to prevent buffer issues
    _animationDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _mapController == null || _isDisposed) return;

      try {
        final bounds = LatLngBounds(
          southwest: LatLng(
            widget.fromLatitude! < widget.toLatitude!
                ? widget.fromLatitude!
                : widget.toLatitude!,
            widget.fromLongitude! < widget.toLongitude!
                ? widget.fromLongitude!
                : widget.toLongitude!,
          ),
          northeast: LatLng(
            widget.fromLatitude! > widget.toLatitude!
                ? widget.fromLatitude!
                : widget.toLatitude!,
            widget.fromLongitude! > widget.toLongitude!
                ? widget.fromLongitude!
                : widget.toLongitude!,
          ),
        );

        // Use moveCamera instead of animateCamera to reduce frame generation
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _mapController != null && !_isDisposed) {
            try {
              _mapController?.moveCamera(
                CameraUpdate.newLatLngBounds(bounds, 100.0),
              );
            } catch (e) {
              // Silent fail - don't spam errors
            }
          }
        });
      } catch (e) {
        // Silent fail
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    // Prevent multiple initializations
    if (_mapController != null || _isDisposed) {
      try {
        controller.dispose();
      } catch (e) {
        // Silent fail
      }
      return;
    }

    _mapController = controller;
    _mapControllerCompleter?.complete(controller);
    
    // Call external callback if provided
    widget.onMapCreated?.call(controller);

    // Mark map as ready immediately - don't delay this
    if (mounted && !_isDisposed) {
      setState(() {
        _isMapReady = true;
      });
      
      // Delay camera animation and route updates to prevent buffer exhaustion
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _mapController != null && !_isDisposed) {
          _animateCameraToBounds();
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Always render the map widget so onMapCreated gets called
    // Show loading overlay on top until map is ready
    return RepaintBoundary(
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Map widget - always rendered so onMapCreated gets called
              GoogleMap(
                key: ValueKey('optimized_map_${widget.uniqueKey}'),
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.fromLatitude ?? 33.6844,
                    widget.fromLongitude ?? 73.0479,
                  ),
                  zoom: 12.0,
                ),
                onMapCreated: _onMapCreated,
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
            zoomControlsEnabled: widget.showControls,
            mapType: MapType.normal,
            zoomGesturesEnabled: true, // Enable for create post screen
            scrollGesturesEnabled: true, // Enable for create post screen
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            compassEnabled: false,
            liteModeEnabled: _useLiteMode, // Disabled to show routes properly
                mapToolbarEnabled: false,
                onTap: widget.onTap,
                // Remove camera listeners that trigger frame updates
                onCameraMoveStarted: null,
                onCameraMove: null,
                onCameraIdle: null,
              ),
              // Loading overlay - shown until map is ready
              if (!_isMapReady)
                Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF49977a)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading map...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.fromLocation != null && widget.toLocation != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${widget.fromLocation} → ${widget.toLocation}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancel all timers immediately
    _animationDebounceTimer?.cancel();
    _animationDebounceTimer = null;

    // Clear markers and polylines immediately to free buffers
    _markers.clear();
    _polylines.clear();

    // Dispose map controller synchronously to free resources immediately
    if (_mapController != null) {
      try {
        _mapController?.dispose();
      } catch (e) {
        // Silent fail during disposal
      }
      _mapController = null;
    }

    super.dispose();
  }
}

