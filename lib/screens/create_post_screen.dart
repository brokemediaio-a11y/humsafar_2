import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/distance_calculator.dart';
import '../widgets/static_map_widget.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postService = PostService();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // Post type
  PostType _postType = PostType.driver;

  // Driver details
  final _carMakeController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carColorController = TextEditingController();
  final _carPlateController = TextEditingController();

  // Route details
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  double? _distanceKm;
  double? _maxPrice;
  Timer? _updateDebounceTimer;

  // Schedule & seats
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  final _totalSeatsController = TextEditingController(text: '3');
  final _pricePerSeatController = TextEditingController();

  // Notes
  final _notesController = TextEditingController();
  final List<String> _selectedTags = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setDefaultPostType();
  }

  Future<bool> _checkUserCanDrive() async {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('CreatePost: No current user found');
      return false;
    }

    final userData = await _firestoreService.getUser(user.uid);
    debugPrint(
      'CreatePost: User data - hasCar: ${userData?.hasCar}, licenseFront: ${userData?.licenseFront != null ? "present" : "null"}, licenseBack: ${userData?.licenseBack != null ? "present" : "null"}',
    );
    return userData?.hasCar ?? false;
  }

  Future<void> _setDefaultPostType() async {
    final canDrive = await _checkUserCanDrive();
    debugPrint('CreatePost: Setting default post type - canDrive: $canDrive');
    if (mounted) {
      setState(() {
        _postType = canDrive ? PostType.driver : PostType.passenger;
      });
    }
  }

  @override
  void dispose() {
    _updateDebounceTimer?.cancel();
    _carMakeController.dispose();
    _carModelController.dispose();
    _carColorController.dispose();
    _carPlateController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _totalSeatsController.dispose();
    _pricePerSeatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Removed _getCurrentLocation - not needed with static maps


  Future<void> _searchLocation(String query, bool isFrom) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        if (isFrom) {
          _fromLatLng = latLng;
        } else {
          _toLatLng = latLng;
        }
        _updateMarkersAndRoute();
        // Update UI to show static map
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
    }
  }

  void _updateMarkersAndRoute() {
    // Debounce updates to prevent rapid setState calls
    _updateDebounceTimer?.cancel();
    _updateDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (_fromLatLng != null && _toLatLng != null) {
        // Calculate distance
        _distanceKm = DistanceCalculator.calculateDistance(
          _fromLatLng!.latitude,
          _fromLatLng!.longitude,
          _toLatLng!.latitude,
          _toLatLng!.longitude,
        );
        _maxPrice = DistanceCalculator.calculateMaxPrice(_distanceKm!);
      }

      // Only call setState to update UI elements (distance, price display)
      // The map widget will update itself via didUpdateWidget
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _selectDepartureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF49977a)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _departureDate = picked);
    }
  }

  Future<void> _selectDepartureTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF49977a)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _departureTime = picked);
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromLatLng == null || _toLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select from and to locations on the map'),
        ),
      );
      return;
    }

    if (_departureDate == null || _departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure date and time')),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create a post')),
      );
      return;
    }

    // Get user data
    final userData = await _firestoreService.getUser(user.uid);
    if (userData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User data not found')));
      return;
    }

    // Check if user can post as driver
    if (_postType == PostType.driver && !userData.hasCar) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only users with cars can post as drivers. Please update your profile.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate price
    final price = int.tryParse(_pricePerSeatController.text);
    if (price == null || price <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    if (_maxPrice != null && price > _maxPrice!) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Price cannot exceed Rs. ${_maxPrice!.toStringAsFixed(0)} (35 × ${_distanceKm!.toStringAsFixed(1)} km + 10% platform fee)',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Combine date and time
    final departureDateTime = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );

    // Create post
    final post = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      userName: userData.fullName,
      userProfileImageUrl: '',
      isVerified: userData.isVerified,
      type: _postType,
      fromLocation: _fromLocationController.text,
      toLocation: _toLocationController.text,
      departureTime: departureDateTime,
      seatsAvailable: int.tryParse(_totalSeatsController.text),
      price: price,
      // Only save car details if not empty
      carMake: _carMakeController.text.trim().isEmpty
          ? null
          : _carMakeController.text.trim(),
      carModel: _carModelController.text.trim().isEmpty
          ? null
          : _carModelController.text.trim(),
      carColor: _carColorController.text.trim().isEmpty
          ? null
          : _carColorController.text.trim(),
      carPlate: _carPlateController.text.trim().isEmpty
          ? null
          : _carPlateController.text.trim(),
      fromLatitude: _fromLatLng!.latitude,
      fromLongitude: _fromLatLng!.longitude,
      toLatitude: _toLatLng!.latitude,
      toLongitude: _toLatLng!.longitude,
      distanceKm: _distanceKm,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      createdAt: DateTime.now(),
    );

    final success = await _postService.createPost(post);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create post. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post type selector
              _buildSectionTitle('I am a'),
              const SizedBox(height: 12),
              _buildPostTypeSelector(),
              const SizedBox(height: 24),
              // Driver details (only show for driver)
              if (_postType == PostType.driver) ...[
                _buildSectionTitle('Driver details'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _carMakeController,
                        label: 'Car make',
                        hint: 'Toyota',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _carModelController,
                        label: 'Model',
                        hint: 'Corolla',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _carColorController,
                        label: 'Color',
                        hint: 'White',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _carPlateController,
                        label: 'Plate',
                        hint: 'ABC-123',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              // Route section
              _buildSectionTitle('Route'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fromLocationController,
                label: 'From',
                hint: 'Hostel 3, Main Campus',
                prefixIcon: Icons.location_on_outlined,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _searchLocation(value, true);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _toLocationController,
                label: 'To',
                hint: 'Central Library',
                prefixIcon: Icons.location_on_outlined,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _searchLocation(value, false);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Map - Use static map to prevent buffer exhaustion
              // Only show when both locations are selected
              if (_fromLatLng != null && _toLatLng != null)
                StaticMapWidget(
                  fromLatitude: _fromLatLng?.latitude,
                  fromLongitude: _fromLatLng?.longitude,
                  toLatitude: _toLatLng?.latitude,
                  toLongitude: _toLatLng?.longitude,
                  fromLocation: _fromLocationController.text.isEmpty
                      ? null
                      : _fromLocationController.text,
                  toLocation: _toLocationController.text.isEmpty
                      ? null
                      : _toLocationController.text,
                  height: 250,
                )
              else
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select "From" and "To" locations',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Map preview will appear here',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Search locations above to see route preview',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (_distanceKm != null && _maxPrice != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Distance: ${_distanceKm!.toStringAsFixed(1)} km | Max Price: Rs. ${_maxPrice!.toStringAsFixed(0)} (35/km + 10% fee)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Schedule & seats
              _buildSectionTitle('Schedule & seats'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDepartureDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _departureDate == null
                                    ? 'DD / MM / YYYY'
                                    : DateFormat('dd / MM / yyyy').format(_departureDate!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _departureDate == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                  fontWeight: _departureDate == null
                                      ? FontWeight.normal
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today_outlined, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectDepartureTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _departureTime == null
                                    ? 'HH : MM'
                                    : _departureTime!.format(context),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _departureTime == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                  fontWeight: _departureTime == null
                                      ? FontWeight.normal
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time_outlined, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _totalSeatsController,
                      label: 'Total seats',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final seats = int.tryParse(value);
                        if (seats == null || seats <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _pricePerSeatController,
                      label: 'Price per seat',
                      hint: 'Rs. 150',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final price = int.tryParse(value);
                        if (price == null || price <= 0) return 'Invalid';
                        if (_maxPrice != null && price > _maxPrice!) {
                          return 'Max: Rs. ${_maxPrice!.toStringAsFixed(0)}';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Notes section
              _buildSectionTitle('Notes (optional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'No smoking, light backpack only.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Female-only', 'Music on', 'AC available'].map((
                  tag,
                ) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag),
                    selectedColor: const Color(
                      0xFF49977a,
                    ).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF49977a),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF49977a)
                          : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF49977a),
                        side: const BorderSide(color: Color(0xFF49977a)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF49977a),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Post Trip'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildPostTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<bool>(
              future: _checkUserCanDrive(),
              builder: (context, snapshot) {
                final canDrive = snapshot.data ?? false;
                return GestureDetector(
                  onTap: () {
                    if (canDrive) {
                      setState(() => _postType = PostType.driver);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Only users with cars can post as drivers',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _postType == PostType.driver
                          ? const Color(0xFF49977a)
                          : canDrive
                          ? Colors.transparent
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Driver',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _postType == PostType.driver
                                ? Colors.white
                                : canDrive
                                ? Colors.black87
                                : Colors.grey.shade500,
                            fontWeight: _postType == PostType.driver
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (!canDrive) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _postType = PostType.passenger),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _postType == PostType.passenger
                      ? const Color(0xFF49977a)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Passenger',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _postType == PostType.passenger
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: _postType == PostType.passenger
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

// Isolated map widget to prevent unnecessary rebuilds
