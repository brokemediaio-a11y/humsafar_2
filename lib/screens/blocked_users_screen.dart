import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../services/block_service.dart';
import '../services/auth_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final BlockService _blockService = BlockService();
  final AuthService _authService = AuthService();
  
  List<BlockModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final blockedUsers = await _blockService.getBlockedUsers(currentUser.uid);
    
    if (mounted) {
      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(BlockModel block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${block.blockedUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF49977a),
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _blockService.unblockUser(
        blockerId: block.blockerId,
        blockedUserId: block.blockedUserId,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _blockedUsers.removeWhere((b) => b.id == block.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${block.blockedUserName} has been unblocked'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to unblock user. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF49977a),
              ),
            )
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Users you block will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 72,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final block = _blockedUsers[index];
                    return Container(
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          block.blockedUserName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blocked on ${_formatDate(block.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (block.reason?.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Reason: ${block.reason}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _unblockUser(block),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF49977a),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Unblock',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}