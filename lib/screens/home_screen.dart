import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import '../widgets/app_header.dart';
import '../widgets/post_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/request_seat_dialog.dart';
import '../widgets/offer_ride_dialog.dart';
import 'login_screen.dart';
import 'create_post_screen.dart';
import 'alerts_screen.dart';
import 'chats_screen.dart';
import 'chat_detail_screen.dart';
import 'journeys_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'all';
  String _searchQuery = '';
  int _currentNavIndex = 0;
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    // Listen to posts stream
    _postService.getAllPosts().listen((posts) {
      if (mounted) {
        setState(() {
          _posts = posts;
        });
      }
    });
  }

  List<PostModel> get _filteredPosts {
    var posts = _posts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      posts = posts.where((post) {
        return post.fromLocation.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            post.toLocation.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            post.userName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter == 'drivers') {
      posts = posts.where((post) => post.type == PostType.driver).toList();
    } else if (_selectedFilter == 'passengers') {
      posts = posts.where((post) => post.type == PostType.passenger).toList();
    }

    // Apply time filter
    if (_selectedFilter == 'now') {
      final now = DateTime.now();
      posts = posts.where((post) {
        if (post.departureTime == null) return false;
        final diff = post.departureTime!.difference(now);
        return diff.inMinutes >= 0 && diff.inMinutes <= 30;
      }).toList();
    } else if (_selectedFilter == 'today') {
      final today = DateTime.now();
      posts = posts.where((post) {
        if (post.departureTime == null) return false;
        return post.departureTime!.year == today.year &&
            post.departureTime!.month == today.month &&
            post.departureTime!.day == today.day;
      }).toList();
    }

    return posts;
  }

  void _handleCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
  }

  void _handleRequestSeat(PostModel post) async {
    // Show request seat dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RequestSeatDialog(post: post),
    );

    // If request was successful, the dialog already shows a toast
    if (result == true && mounted) {
      // Optionally refresh the posts or show additional feedback
    }
  }

  void _handleOfferRide(PostModel post) async {
    // Show offer ride dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => OfferRideDialog(post: post),
    );

    // If offer was successful, the dialog already shows a toast
    if (result == true && mounted) {
      // Optionally refresh or show additional feedback
    }
  }

  void _handleMessage(PostModel post) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send messages')),
      );
      return;
    }

    // Get current user data
    final currentUserData = await _firestoreService.getUser(currentUser.uid);
    if (currentUserData == null || !mounted) return;

    // Get or create chat
    final chatId = await _chatService.getOrCreateChat(
      currentUserId: currentUser.uid,
      currentUserName: currentUserData.fullName,
      currentUserImage: '',
      otherUserId: post.userId,
      otherUserName: post.userName,
      otherUserImage: post.userProfileImageUrl,
    );

    if (!mounted) return;

    // Navigate to chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatId: chatId,
          otherUserId: post.userId,
          otherUserName: post.userName,
          otherUserImage: post.userProfileImageUrl,
        ),
      ),
    );
  }

  void _handleMenuTap() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('About coming soon!')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _authService.signOut();
                if (!mounted) return;
                // Use the State's context, not the builder's context
                final navigator = Navigator.of(this.context);
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Handle navigation for different tabs
    if (index == 0) {
      // Home - already here
      return;
    } else if (index == 1) {
      // Journeys tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const JourneysScreen()),
      ).then((_) {
        // Reset nav index when coming back
        if (mounted) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      });
    } else if (index == 2) {
      // Chats tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatsScreen()),
      ).then((_) {
        // Reset nav index when coming back
        if (mounted) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      });
    } else if (index == 3) {
      // Alerts tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AlertsScreen()),
      ).then((_) {
        // Reset nav index when coming back
        if (mounted) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      });
    } else if (index == 4) {
      // Profile tab
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) {
        // Reset nav index when coming back
        if (mounted) {
          setState(() {
            _currentNavIndex = 0;
          });
        }
      });
    } else {
      // Other tabs - show coming soon
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature is coming soon!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            AppHeader(
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              onMenuTap: _handleMenuTap,
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            // Posts feed
            Expanded(
              child: _filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No posts found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = _filteredPosts[index];
                        return PostCard(
                          post: post,
                          onRequestSeat: post.type == PostType.driver
                              ? () => _handleRequestSeat(post)
                              : null,
                          onOfferRide: post.type == PostType.passenger
                              ? () => _handleOfferRide(post)
                              : null,
                          onMessage: () => _handleMessage(post),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreatePost,
        backgroundColor: const Color(0xFF49977a),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: currentUser != null
          ? StreamBuilder<int>(
              stream: _bookingService.getUnreadAlertsCount(currentUser.uid),
              builder: (context, snapshot) {
                return BottomNavBar(
                  currentIndex: _currentNavIndex,
                  onTap: _onNavTap,
                  unreadAlertsCount: snapshot.data,
                );
              },
            )
          : BottomNavBar(currentIndex: _currentNavIndex, onTap: _onNavTap),
    );
  }
}
