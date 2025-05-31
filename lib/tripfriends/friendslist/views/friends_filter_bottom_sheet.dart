// lib/tripfriends/friendslist/views/friends_filter_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../constants/filter_constants.dart';

class FriendsFilterBottomSheet extends StatefulWidget {
  final Map<String, Set<String>> currentFilters;
  final Function(Map<String, Set<String>>) onFiltersApplied;

  const FriendsFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  static void show(
      BuildContext context, {
        required Map<String, Set<String>> currentFilters,
        required Function(Map<String, Set<String>>) onFiltersApplied,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FriendsFilterBottomSheet(
        currentFilters: currentFilters,
        onFiltersApplied: onFiltersApplied,
      ),
    );
  }

  @override
  State<FriendsFilterBottomSheet> createState() => _FriendsFilterBottomSheetState();
}

class _FriendsFilterBottomSheetState extends State<FriendsFilterBottomSheet> {
  late Map<String, Set<String>> _selectedFilters;

  @override
  void initState() {
    super.initState();
    // 현재 필터 상태 복사
    _selectedFilters = Map.from(widget.currentFilters.map(
          (key, value) => MapEntry(key, Set<String>.from(value)),
    ));
  }

  void _toggleFilter(String category, String option, bool selected) {
    setState(() {
      _selectedFilters[category] ??= {};

      if (selected) {
        // 같은 카테고리의 다른 선택 제거 (라디오 버튼처럼)
        _selectedFilters[category]!.clear();
        _selectedFilters[category]!.add(option);
      } else {
        _selectedFilters[category]!.remove(option);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedFilters.clear();
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(_selectedFilters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(),
          Expanded(child: _buildFilterOptions()),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '필터',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              '초기화',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: FilterConstants.filterOptions.entries.map((entry) {
            return _buildFilterCategory(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterCategory(String category, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = _selectedFilters[category]?.contains(option) ?? false;

            return GestureDetector(
              onTap: () => _toggleFilter(category, option, !isSelected),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: ShapeDecoration(
                  color: isSelected ? const Color(0xFF3182F6) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF3182F6) : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: InkWell(
        onTap: _applyFilters,
        child: Container(
          height: 48,
          decoration: ShapeDecoration(
            color: const Color(0xFF3182F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: const Center(
            child: Text(
              '필터적용',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}