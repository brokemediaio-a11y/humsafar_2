import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String? searchQuery;
  final Function(String)? onSearchChanged;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    this.searchQuery,
    this.onSearchChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.onMenuTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Logo and top section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                  width: 120,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if logo not found
                    return Row(
                      children: [
                        Text(
                          'مسافر',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF49977a),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.directions_car,
                          size: 20,
                          color: const Color(0xFF49977a),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                // Menu and Profile buttons
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMenuTap,
                  color: Colors.grey.shade700,
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: onProfileTap,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search rides, people, zones',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.grey),
                    onPressed: () {
                      // Open filter dialog
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter buttons
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Drivers',
                  isSelected: selectedFilter == 'drivers',
                  onTap: () => onFilterChanged('drivers'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Passengers',
                  isSelected: selectedFilter == 'passengers',
                  onTap: () => onFilterChanged('passengers'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Now',
                  isSelected: selectedFilter == 'now',
                  onTap: () => onFilterChanged('now'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Today',
                  isSelected: selectedFilter == 'today',
                  onTap: () => onFilterChanged('today'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'For you',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Safe, verified rides',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF49977a)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

