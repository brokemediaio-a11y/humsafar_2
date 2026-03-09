import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_search_service.dart';
import '../services/auth_service.dart';

class UserMentionField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool isRequired;

  const UserMentionField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 3,
    this.validator,
    this.isRequired = false,
  });

  @override
  State<UserMentionField> createState() => _UserMentionFieldState();
}

class _UserMentionFieldState extends State<UserMentionField> {
  final UserSearchService _userSearchService = UserSearchService();
  final AuthService _authService = AuthService();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<UserModel> _filteredUsers = [];
  String _currentQuery = '';
  int _selectedIndex = 0;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;
    
    if (cursorPosition == -1) {
      _removeOverlay();
      return;
    }

    // Find the last @ symbol before cursor
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');
    
    if (lastAtIndex == -1) {
      _removeOverlay();
      return;
    }

    // Check if there's a space after @ (means @ is not active)
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ')) {
      _removeOverlay();
      return;
    }

    // Get the query after @
    final query = textAfterAt.trim();
    
    if (query != _currentQuery) {
      _currentQuery = query;
      _searchUsers(query);
    }

    if (!_showSuggestions && _filteredUsers.isNotEmpty) {
      _showOverlay();
    }
  }

  Future<void> _searchUsers(String query) async {
    final currentUser = _authService.currentUser;
    final excludeUserId = currentUser?.uid;

    if (query.isEmpty) {
      // Show all users when just @ is typed
      final allUsers = await _userSearchService.searchUsers('', excludeUserId: excludeUserId);
      if (mounted) {
        setState(() {
          _filteredUsers = allUsers.take(10).toList(); // Limit to 10 for performance
          _selectedIndex = 0;
        });
        if (_filteredUsers.isNotEmpty && _showSuggestions) {
          _updateOverlay();
        }
      }
    } else {
      final results = await _userSearchService.searchUsers(query, excludeUserId: excludeUserId);
      if (mounted) {
        setState(() {
          _filteredUsers = results.take(10).toList();
          _selectedIndex = 0;
        });
        if (_filteredUsers.isNotEmpty && _showSuggestions) {
          _updateOverlay();
        } else if (_filteredUsers.isEmpty && _showSuggestions) {
          _removeOverlay();
        }
      }
    }
  }

  void _showOverlay() {
    if (_filteredUsers.isEmpty) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showSuggestions = true;
    });
  }

  void _updateOverlay() {
    _removeOverlay();
    if (_filteredUsers.isNotEmpty) {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _showSuggestions = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        top: offset.dy + size.height + 4,
        left: offset.dx,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final isSelected = index == _selectedIndex;
                  
                  return InkWell(
                    onTap: () => _selectUser(user),
                    child: Container(
                      color: isSelected ? Colors.grey.shade100 : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade300,
                            child: user.profileImageUrl?.isNotEmpty == true
                                ? ClipOval(
                                    child: Image.network(
                                      user.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 32,
                                      height: 32,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                if (user.studentId.isNotEmpty)
                                  Text(
                                    user.studentId,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectUser(UserModel user) {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;
    
    if (cursorPosition == -1) {
      _removeOverlay();
      return;
    }

    // Find the last @ symbol before cursor
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');
    
    if (lastAtIndex == -1) {
      _removeOverlay();
      return;
    }

    // Replace @query with @username
    final textBeforeAt = text.substring(0, lastAtIndex);
    final textAfterCursor = text.substring(cursorPosition);
    final newText = '$textBeforeAt@${user.fullName} $textAfterCursor';
    
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: lastAtIndex + user.fullName.length + 2, // +2 for @ and space
    );

    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isRequired ? Colors.red.shade300 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isRequired ? Colors.red.shade300 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isRequired ? Colors.red.shade600 : const Color(0xFF49977a),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: widget.isRequired ? Colors.red.shade50 : Colors.grey.shade50,
          prefixIcon: Icon(
            widget.isRequired ? Icons.group : Icons.note,
            color: widget.isRequired ? Colors.red.shade600 : Colors.grey.shade600,
          ),
        ),
        validator: widget.validator,
        onTap: () {
          // Trigger search when field is tapped and contains @
          if (widget.controller.text.contains('@')) {
            _onTextChanged();
          }
        },
      ),
    );
  }
}
