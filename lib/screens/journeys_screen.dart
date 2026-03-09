import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/journey_model.dart';
import '../utils/phone_dialer.dart';
import '../models/rating_model.dart';
import '../services/journey_service.dart';
import '../services/auth_service.dart';
import '../services/rating_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../widgets/static_map_widget.dart';
import '../widgets/rating_dialog.dart';
import 'chat_detail_screen.dart';

class JourneysScreen extends StatefulWidget {
  const JourneysScreen({super.key});

  @override
  State<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends State<JourneysScreen>
    with SingleTickerProviderStateMixin {
  final JourneyService _journeyService = JourneyService();
  final AuthService _authService = AuthService();
  final RatingService _ratingService = RatingService();
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  Timer? _timer;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Check for pending ratings when user views completed tab
        if (_tabController.index == 2) {
          _checkPendingRatings();
        }
      }
    });
    // Refresh every 30 seconds to update "can start" status and active ride timer
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    // Check for pending ratings when screen loads
    _checkPendingRatings();
  }

  Future<void> _checkPendingRatings() async {
    // Wait a bit for the screen to be fully built
    await Future.delayed(const Duration(milliseconds: 800));
    
    final currentUser = _authService.currentUser;
    if (currentUser == null || !mounted) return;

    try {
      // Get all completed journeys for this user
      // Use timeout to prevent hanging
      final journeys = await _journeyService
          .getUserJourneys(currentUser.uid)
          .timeout(const Duration(seconds: 5))
          .first;
      
      if (!mounted) return;
      
      final completedJourneys = journeys.where((j) => j.status == JourneyStatus.completed).toList();

      // Check each completed journey for pending ratings
      for (final journey in completedJourneys) {
        if (!mounted) return;
        
        final isDriver = journey.isDriver(currentUser.uid);

        if (isDriver) {
          // Driver needs to rate passengers
          for (final passenger in journey.passengers) {
            if (!mounted) return;
            
            final hasRated = await _ratingService.hasUserRated(
              journeyId: journey.id,
              raterId: currentUser.uid,
              ratedUserId: passenger.passengerId,
            );

            if (!hasRated && mounted) {
              await showRatingDialog(
                context: context,
                journeyId: journey.id,
                userToRateId: passenger.passengerId,
                userToRateName: passenger.passengerName,
                currentUserId: currentUser.uid,
                currentUserName: journey.driverName,
                ratingType: RatingType.driver_to_passenger,
              );
              // Small delay between dialogs
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        } else {
          // Passenger needs to rate driver
          final hasRated = await _ratingService.hasUserRated(
            journeyId: journey.id,
            raterId: currentUser.uid,
            ratedUserId: journey.driverId,
          );

          if (!hasRated && mounted) {
            await showRatingDialog(
              context: context,
              journeyId: journey.id,
              userToRateId: journey.driverId,
              userToRateName: journey.driverName,
              currentUserId: currentUser.uid,
              currentUserName: _getCurrentUserName(journey, currentUser.uid),
              ratingType: RatingType.passenger_to_driver,
            );
            // Only show one rating dialog at a time for passengers
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking pending ratings: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleStartRide(JourneyModel journey) async {
    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Ride'),
        content: Text(
          'Start your journey to ${journey.toLocation}?\n\n'
          'Timer will begin and passengers will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF49977a),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Ride'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Start the ride
    final success = await _journeyService.startRide(journey.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Ride started! Drive safely.')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start ride. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEndRide(JourneyModel journey) async {
    // Calculate total earnings
    final totalEarnings = journey.calculateEarnings();
    
    // Calculate duration
    String rideDuration = '0 min';
    if (journey.startTime != null) {
      final duration = DateTime.now().difference(journey.startTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (hours > 0) {
        rideDuration = '$hours hr $minutes min';
      } else {
        rideDuration = '$minutes min';
      }
    }

    // Show receipt-style confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF49977a).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF49977a),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Complete your journey',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                
                const SizedBox(height: 16),
                
                // Route Details
                _buildReceiptRow(
                  icon: Icons.location_on,
                  iconColor: Colors.green,
                  label: 'From',
                  value: journey.fromLocation,
                ),
                const SizedBox(height: 12),
                _buildReceiptRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  label: 'To',
                  value: journey.toLocation,
                ),
                
                const SizedBox(height: 16),
                
                // Ride Details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: rideDuration,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.straighten_outlined,
                        label: 'Distance',
                        value: journey.distanceKm != null
                            ? '${journey.distanceKm!.toStringAsFixed(1)} km'
                            : 'N/A',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Passengers List
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Passengers (${journey.passengers.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...journey.passengers.map((passenger) {
                        final passengerEarning =
                            passenger.seatsBooked * journey.pricePerSeat;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  passenger.passengerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${passenger.seatsBooked} × Rs. ${journey.pricePerSeat}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. $passengerEarning',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF49977a),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Total Earnings
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF49977a),
                        const Color(0xFF49977a).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You earned from this ride',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rs. $totalEarnings',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Complete Ride',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    // End the ride with earnings
    final success = await _journeyService.endRide(journey.id, totalEarnings);

    if (!mounted) return;

    if (success) {
      // Force refresh the UI immediately
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ride completed! You earned Rs. $totalEarnings',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      // Show rating dialogs for driver and passengers
      await _showRatingDialogs(journey);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to end ride. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRatingDialogs(JourneyModel journey) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final isDriver = journey.isDriver(currentUser.uid);

    if (isDriver) {
      // Driver rates each passenger
      for (final passenger in journey.passengers) {
        final hasRated = await _ratingService.hasUserRated(
          journeyId: journey.id,
          raterId: currentUser.uid,
          ratedUserId: passenger.passengerId,
        );

        if (!hasRated && mounted) {
          await showRatingDialog(
            context: context,
            journeyId: journey.id,
            userToRateId: passenger.passengerId,
            userToRateName: passenger.passengerName,
            currentUserId: currentUser.uid,
            currentUserName: journey.driverName,
            ratingType: RatingType.driver_to_passenger,
          );
        }
      }
    } else {
      // Passenger rates driver
      final hasRated = await _ratingService.hasUserRated(
        journeyId: journey.id,
        raterId: currentUser.uid,
        ratedUserId: journey.driverId,
      );

      if (!hasRated && mounted) {
        await showRatingDialog(
          context: context,
          journeyId: journey.id,
          userToRateId: journey.driverId,
          userToRateName: journey.driverName,
          currentUserId: currentUser.uid,
          currentUserName: _getCurrentUserName(journey, currentUser.uid),
          ratingType: RatingType.passenger_to_driver,
        );
      }
    }
  }

  String _getCurrentUserName(JourneyModel journey, String userId) {
    final passenger = journey.passengers.firstWhere(
      (p) => p.passengerId == userId,
      orElse: () => PassengerInfo(
        passengerId: userId, 
        passengerName: 'Passenger', 
        passengerProfileImage: '',
        seatsBooked: 1,
      ),
    );
    return passenger.passengerName;
  }

  Future<void> _callSOS() async {
    try {
      const phoneNumber = '15';
      
      // Try platform channel first (requires full rebuild)
      try {
        final dialed = await PhoneDialer.dial(phoneNumber);
        if (dialed) {
          return; // Success - phone dialer opened
        }
      } catch (e) {
        debugPrint('Platform channel failed (may need rebuild): $e');
      }
      
      // Fallback: Use url_launcher with simpler approach
      try {
        final uri = Uri.parse('tel:$phoneNumber');
        // Try without checking canLaunchUrl first
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return; // Assume success if no exception
      } catch (e) {
        debugPrint('url_launcher failed: $e');
      }
      
      // If both fail, show manual dial message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please dial 15 manually for emergency'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error launching SOS: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone dialer. Please dial 15 manually.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _messageUser({
    required String userId,
    required String userName,
    String? userImage,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Get current user data
    final currentUserData = await _firestoreService.getUser(currentUser.uid);
    if (currentUserData == null || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF49977a)),
      ),
    );

    try {
      // Get or create chat
      final chatId = await _chatService.getOrCreateChat(
        currentUserId: currentUser.uid,
        currentUserName: currentUserData.fullName,
        currentUserImage: currentUserData.profileImageUrl ?? '',
        otherUserId: userId,
        otherUserName: userName,
        otherUserImage: userImage ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatId,
            otherUserId: userId,
            otherUserName: userName,
            otherUserImage: userImage ?? '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReceiptRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF49977a)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view journeys')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Journeys',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF49977a),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF49977a),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildActiveJourneys(currentUser.uid),
          _buildUpcomingJourneys(currentUser.uid),
          _buildCompletedJourneys(currentUser.uid),
        ],
      ),
    );
  }

  Widget _buildActiveJourneys(String driverId) {
    return StreamBuilder<JourneyModel?>(
      stream: _journeyService.getActiveJourney(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeJourney = snapshot.data;

        if (activeJourney == null) {
          return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drive_eta_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active ride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a ride from upcoming journeys',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildActiveJourneyCard(activeJourney),
        );
      },
    );
  }

  Widget _buildUpcomingJourneys(String driverId) {
    return StreamBuilder<List<JourneyModel>>(
      stream: _journeyService.getUpcomingJourneys(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final journeys = snapshot.data ?? [];

        if (journeys.isEmpty) {
          return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No upcoming journeys',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a post to add journeys',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: journeys.length,
          itemBuilder: (context, index) {
            return _buildUpcomingJourneyCard(journeys[index]);
          },
        );
      },
    );
  }

  Widget _buildCompletedJourneys(String driverId) {
    return StreamBuilder<List<JourneyModel>>(
      stream: _journeyService.getCompletedJourneys(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final journeys = snapshot.data ?? [];

        if (journeys.isEmpty) {
          return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No completed journeys',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your ride history will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: journeys.length,
          itemBuilder: (context, index) {
            return _buildCompletedJourneyCard(journeys[index]);
          },
        );
      },
    );
  }

  Widget _buildActiveJourneyCard(JourneyModel journey) {
    final currentUser = _authService.currentUser;
    final isDriver = currentUser != null && journey.isDriver(currentUser.uid);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF49977a).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF49977a),
                  const Color(0xFF49977a).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDriver ? Icons.directions_car : Icons.airport_shuttle,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDriver ? 'RIDE IN PROGRESS' : 'RIDING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildTimer(journey),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                _buildRouteInfo(journey),
                
                const SizedBox(height: 16),
                
                // Map - Use static map to prevent buffer exhaustion
                if (journey.fromLatitude != null &&
                    journey.fromLongitude != null &&
                    journey.toLatitude != null &&
                    journey.toLongitude != null)
                  StaticMapWidget(
                    fromLatitude: journey.fromLatitude,
                    fromLongitude: journey.fromLongitude,
                    toLatitude: journey.toLatitude,
                    toLongitude: journey.toLongitude,
                    fromLocation: journey.fromLocation,
                    toLocation: journey.toLocation,
                    height: 200,
                  ),

                const SizedBox(height: 16),

                // Passengers (only show for drivers)
                if (isDriver) ...[
                  _buildPassengersList(journey),
                  const SizedBox(height: 20),
                ] else ...[
                  // Show driver info for passengers
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade300,
                          child: journey.driverProfileImage.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    journey.driverProfileImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, size: 20);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Driver',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                journey.driverName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Share and SOS buttons for passengers
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // SOS button (only for passengers)
                            if (!isDriver)
                              IconButton(
                                onPressed: _callSOS,
                                icon: const Icon(Icons.emergency),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade600,
                                ),
                                tooltip: 'Emergency SOS',
                              ),
                            const SizedBox(width: 8),
                            // Message driver button (only for passengers)
                            if (!isDriver)
                              IconButton(
                                onPressed: () => _messageUser(
                                  userId: journey.driverId,
                                  userName: journey.driverName,
                                  userImage: journey.driverProfileImage,
                                ),
                                icon: const Icon(Icons.chat_bubble_outline),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: Colors.blue.shade600,
                                ),
                                tooltip: 'Message driver',
                              ),
                            const SizedBox(width: 8),
                            // Share button
                            IconButton(
                              onPressed: () => _shareRideInfo(journey),
                              icon: const Icon(Icons.share),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: const Color(0xFF49977a),
                              ),
                              tooltip: 'Share ride info',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // End Ride Button (only for drivers)
                if (isDriver)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _handleEndRide(journey),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stop_circle_outlined,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'End Ride',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingJourneyCard(JourneyModel journey) {
    final currentUser = _authService.currentUser;
    final isDriver = currentUser != null && journey.isDriver(currentUser.uid);
    final canStart = isDriver && journey.canStart();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Departure Time
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: canStart ? const Color(0xFF49977a) : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  journey.departureTime != null
                      ? DateFormat('MMM d, yyyy • h:mm a')
                          .format(journey.departureTime!)
                      : 'Not scheduled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: canStart ? const Color(0xFF49977a) : Colors.grey,
                  ),
                ),
                if (canStart) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF49977a).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ready to start',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF49977a),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Route
            _buildRouteInfo(journey),

            const SizedBox(height: 12),

            // Passengers count and car info
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '${journey.passengers.length} passenger${journey.passengers.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                if (journey.carPlate != null) ...[
                  Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    journey.carPlate!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Passengers list with message buttons (for drivers)
            if (isDriver && journey.passengers.isNotEmpty) ...[
              _buildPassengersList(journey),
              const SizedBox(height: 12),
            ],

            // Message driver button (for passengers)
            if (!isDriver) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _messageUser(
                        userId: journey.driverId,
                        userName: journey.driverName,
                        userImage: journey.driverProfileImage,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text('Message ${journey.driverName}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF49977a),
                        side: const BorderSide(color: Color(0xFF49977a)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Start Ride Button (only for drivers)
            if (isDriver)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: canStart ? () => _handleStartRide(journey) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF49977a),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        canStart ? Icons.play_circle_outline : Icons.lock_clock,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          canStart ? 'Start Ride' : 'Not ready yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Passenger view - show waiting message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for driver to start ride',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedJourneyCard(JourneyModel journey) {
    final currentUser = _authService.currentUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completed badge and date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (journey.endTime != null)
                  Text(
                    DateFormat('MMM d, yyyy').format(journey.endTime!),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Route
            _buildRouteInfo(journey),

            const SizedBox(height: 12),

            // Duration and passengers
            Row(
              children: [
                if (journey.durationMinutes != null) ...[
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(journey.durationMinutes!),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(
                  Icons.people_outline,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '${journey.passengers.length} passenger${journey.passengers.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            // Only show earnings to drivers
            if (currentUser != null && journey.isDriver(currentUser.uid) && journey.totalEarnings != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF49977a).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: const Color(0xFF49977a),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Earned: Rs. ${journey.totalEarnings}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF49977a),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(JourneyModel journey) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 24,
              color: Colors.grey.shade300,
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journey.fromLocation,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Text(
                journey.toLocation,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (journey.distanceKm != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${journey.distanceKm!.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPassengersList(JourneyModel journey) {
    if (journey.passengers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passengers (${journey.passengers.length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...journey.passengers.map((passenger) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade300,
                  child: passenger.passengerProfileImage.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            passenger.passengerProfileImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 18);
                            },
                          ),
                        )
                      : const Icon(Icons.person, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.passengerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${passenger.seatsBooked} seat${passenger.seatsBooked > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Message button for drivers to message passengers
                IconButton(
                  onPressed: () => _messageUser(
                    userId: passenger.passengerId,
                    userName: passenger.passengerName,
                    userImage: passenger.passengerProfileImage,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF49977a).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFF49977a),
                    padding: const EdgeInsets.all(8),
                  ),
                  tooltip: 'Message ${passenger.passengerName}',
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimer(JourneyModel journey) {
    if (journey.startTime == null) {
      return const Text(
        '00:00',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
    }

    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final duration = DateTime.now().difference(journey.startTime!);
        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Text(
          '$hours:$minutes:$seconds',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }

  void _shareRideInfo(JourneyModel journey) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final isDriver = journey.isDriver(currentUser.uid);
    final departureTime = journey.departureTime != null
        ? DateFormat('MMM d, yyyy - h:mm a').format(journey.departureTime!)
        : 'Not specified';

    String shareText = '';
    
    if (isDriver) {
      // Driver sharing
      shareText = '''
🚗 HumSafar Ride Details

📍 Route: ${journey.fromLocation} → ${journey.toLocation}
📅 Departure: $departureTime
🚙 Vehicle: ${journey.carMake} ${journey.carModel} (${journey.carColor})
🔢 License: ${journey.carPlate}
👥 Passengers: ${journey.passengers.length}/${journey.totalSeats}

Passengers:
${journey.passengers.map((p) => '• ${p.passengerName} (${p.seatsBooked} seat${p.seatsBooked > 1 ? 's' : ''})').join('\n')}

💰 Rate: Rs. ${journey.pricePerSeat} per seat
📱 Shared via HumSafar App
      ''';
    } else {
      // Passenger sharing
      shareText = '''
🚗 My HumSafar Ride

📍 Route: ${journey.fromLocation} → ${journey.toLocation}
📅 Departure: $departureTime
👨‍✈️ Driver: ${journey.driverName}
🚙 Vehicle: ${journey.carMake} ${journey.carModel} (${journey.carColor})
🔢 License: ${journey.carPlate}
👥 Total Passengers: ${journey.passengers.length}

All Passengers:
${journey.passengers.map((p) => '• ${p.passengerName} (${p.seatsBooked} seat${p.seatsBooked > 1 ? 's' : ''})').join('\n')}

💰 Rate: Rs. ${journey.pricePerSeat} per seat
📱 Shared via HumSafar App
      ''';
    }

    // Copy to clipboard and show snackbar
    Clipboard.setData(ClipboardData(text: shareText.trim()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ride details copied to clipboard! You can now share it on WhatsApp or any other platform.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF49977a),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

