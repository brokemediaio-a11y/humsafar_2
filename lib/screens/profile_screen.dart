import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journey_model.dart';
import '../models/user_model.dart';
import '../models/rating_model.dart';
import '../services/auth_service.dart';
import '../services/journey_service.dart';
import '../services/user_service.dart';
import '../services/rating_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final JourneyService _journeyService = JourneyService();
  final UserService _userService = UserService();
  final RatingService _ratingService = RatingService();
  
  late TabController _tabController;
  UserModel? _userProfile;
  bool _isLoading = true;
  List<JourneyModel> _cachedJourneys = [];
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final profile = await _userService.getUserProfile(currentUser.uid);
      debugPrint('Profile loaded: ${profile != null ? "Success" : "Null"}');
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user profile: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view profile')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    try {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              _buildProfileHeader(currentUser),
            ];
          },
          body: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF49977a),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF49977a),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Journeys'),
                    Tab(text: 'Earnings'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(currentUser.uid),
                      _buildJourneysTab(currentUser.uid),
                      _buildEarningsTab(currentUser.uid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error building profile screen: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading profile'),
              const SizedBox(height: 8),
              Text('$e', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildProfileHeader(user) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF49977a),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF49977a),
                  const Color(0xFF49977a).withValues(alpha: 0.8),
                ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Profile Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    backgroundImage: _userProfile?.profileImageUrl != null &&
                            _userProfile!.profileImageUrl!.isNotEmpty
                        ? NetworkImage(_userProfile!.profileImageUrl!)
                        : null,
                    child: _userProfile?.profileImageUrl == null ||
                            _userProfile!.profileImageUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF49977a),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  _userProfile != null && _userProfile!.fullName.isNotEmpty
                      ? _userProfile!.fullName 
                      : (user.displayName ?? user.email?.split('@').first ?? 'User'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  user.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Member since
                if (_userProfile?.createdAt != null)
                  Text(
                    'Member since ${DateFormat('MMM yyyy').format(_userProfile!.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildOverviewTab(String userId) {
    return StreamBuilder<List<JourneyModel>>(
      stream: _journeyService.getUserJourneys(userId),
      builder: (context, snapshot) {
        // Handle errors first
        if (snapshot.hasError) {
          debugPrint('Error loading journeys: ${snapshot.error}');
          return _buildOverviewContent(_cachedJourneys);
        }

        // Update cache when we get new data
        if (snapshot.hasData) {
          _cachedJourneys = snapshot.data!;
          _hasLoadedOnce = true;
        }

        // Show loading only if we've never loaded data before
        if (!_hasLoadedOnce && snapshot.connectionState == ConnectionState.waiting) {
          // Add a timeout to prevent endless loading
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && !_hasLoadedOnce) {
              setState(() {
                _hasLoadedOnce = true;
              });
            }
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Always show content with cached data
        return _buildOverviewContent(_cachedJourneys);
      },
    );
  }

  Widget _buildOverviewContent(List<JourneyModel> journeys) {
    final completedJourneys = journeys.where((j) => j.status == JourneyStatus.completed).toList();
    final totalEarnings = completedJourneys.fold<double>(
      0.0,
      (sum, journey) => sum + (journey.totalEarnings ?? 0.0),
    );
    final totalRides = completedJourneys.length;
    final totalPassengers = completedJourneys.fold<int>(
      0,
      (sum, journey) => sum + journey.passengers.length,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.directions_car,
                  title: 'Total Rides',
                  value: totalRides.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  title: 'Passengers',
                  value: totalPassengers.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.payments,
                  title: 'Total Earnings',
                  value: 'Rs. ${totalEarnings.toStringAsFixed(0)}',
                  color: const Color(0xFF49977a),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<List<RatingModel>>(
                  future: _authService.currentUser != null
                      ? _ratingService.getRatingsReceivedByUser(_authService.currentUser!.uid)
                      : Future.value([]),
                  builder: (context, snapshot) {
                    final ratings = snapshot.data ?? [];
                    final rating = _userProfile?.rating ?? 0.0;
                    final totalRatings = ratings.length;
                    final ratingText = rating > 0 
                        ? '${rating.toStringAsFixed(1)}${totalRatings > 0 ? ' ($totalRatings)' : ''}'
                        : 'No ratings';
                    
                    return _buildStatCard(
                      icon: Icons.star,
                      title: 'Rating',
                      value: ratingText,
                      color: Colors.orange,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Reviews Section
          _buildReviewsSection(),
          const SizedBox(height: 24),
          // Personal Information
          _buildPersonalInfo(),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return FutureBuilder<List<RatingModel>>(
      future: _ratingService.getRatingsReceivedByUser(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ratings = snapshot.data ?? [];
        
        if (ratings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Reviews (${ratings.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...ratings.take(5).map((rating) => _buildReviewCard(rating)),
              if (ratings.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'And ${ratings.length - 5} more review(s)...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(RatingModel rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Star rating
              ...List.generate(5, (index) {
                return Icon(
                  index < rating.rating.round()
                      ? Icons.star
                      : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                );
              }),
              const Spacer(),
              // Date
              Text(
                DateFormat('MMM d, yyyy').format(rating.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reviewer name
          Text(
            rating.raterName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Review text
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rating.review!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Full Name', 
            _userProfile != null && _userProfile!.fullName.isNotEmpty 
                ? _userProfile!.fullName 
                : 'Not provided'),
          _buildInfoRow(Icons.phone, 'Phone', _userProfile?.phone ?? 'Not provided'),
          _buildInfoRow(Icons.cake, 'Date of Birth', 
            _userProfile?.dateOfBirth != null 
              ? DateFormat('MMM d, yyyy').format(_userProfile!.dateOfBirth)
              : 'Not provided'
          ),
          _buildInfoRow(Icons.badge, 'CNIC', _userProfile?.cnic ?? 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneysTab(String userId) {
    // Use cached data instead of stream to prevent loading issues
    return _buildJourneysContent(_cachedJourneys);
  }

  Widget _buildJourneysContent(List<JourneyModel> journeys) {
    final completedJourneys = journeys
        .where((j) => j.status == JourneyStatus.completed)
        .toList()
      ..sort((a, b) => (b.endTime ?? DateTime.now()).compareTo(a.endTime ?? DateTime.now()));

    if (completedJourneys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No completed journeys yet',
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
      itemCount: completedJourneys.length,
      itemBuilder: (context, index) {
        return _buildJourneyCard(completedJourneys[index]);
      },
    );
  }

  Widget _buildJourneyCard(JourneyModel journey) {
    final isDriver = _authService.currentUser != null && 
                    journey.isDriver(_authService.currentUser!.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
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
          Row(
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
                    height: 30,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      journey.toLocation,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details
          Row(
            children: [
              if (journey.durationMinutes != null) ...[
                Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(journey.durationMinutes!),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
              ],
              Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${journey.passengers.length} passenger${journey.passengers.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (isDriver && journey.totalEarnings != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF49977a).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Rs. ${journey.totalEarnings}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF49977a),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab(String userId) {
    // Use cached data instead of stream to prevent loading issues
    return _buildEarningsContent(_cachedJourneys);
  }

  Widget _buildEarningsContent(List<JourneyModel> journeys) {
    final completedJourneys = journeys
        .where((j) => j.status == JourneyStatus.completed && 
                     j.isDriver(_authService.currentUser!.uid))
        .toList();

    if (completedJourneys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No earnings yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete rides as a driver to see earnings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final totalEarnings = completedJourneys.fold<double>(
          0.0,
          (sum, journey) => sum + (journey.totalEarnings ?? 0.0),
        );

        // Group by month
        final monthlyEarnings = <String, double>{};
        for (final journey in completedJourneys) {
          if (journey.endTime != null) {
            final monthKey = DateFormat('MMM yyyy').format(journey.endTime!);
            monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0.0) + 
                                      (journey.totalEarnings ?? 0.0);
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Total Earnings Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF49977a),
                      const Color(0xFF49977a).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Earnings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${totalEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${completedJourneys.length} completed ride${completedJourneys.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Monthly Breakdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...monthlyEarnings.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            'Rs. ${entry.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF49977a),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}
