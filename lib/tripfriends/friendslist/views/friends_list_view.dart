// lib/tripfriends/friendslist/views/friends_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../core/friends_state_manager.dart';
import '../widgets/friends_list_header.dart';
import '../widgets/selected_filters_display.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/friends_list_item.dart';
import '../../detail/friends_detail_page.dart';
import 'friends_filter_bottom_sheet.dart';

class FriendsListView extends StatefulWidget {
  final List<String>? friendUserIds;

  const FriendsListView({
    super.key,
    this.friendUserIds,
  });

  @override
  State<FriendsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> {
  late final FriendsStateManager _manager;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _manager = FriendsStateManager.instance;
    // 매번 새로 로드
    _manager.clearCache();
    _loadData();
  }

  @override
  void didUpdateWidget(FriendsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // friendUserIds가 변경되면 다시 로드
    if (oldWidget.friendUserIds != widget.friendUserIds) {
      _streamSubscription?.cancel();
      _manager.clearCache();
      _loadData();
    }
  }

  void _loadData() async {
    // 초기화 먼저 수행
    await _manager.initialize();

    // 스트림으로 데이터 로드
    final stream = _manager.loadFriendsStream(specificIds: widget.friendUserIds);
    _streamSubscription = stream.listen(
          (friends) {
        print('FriendsListView: 받은 친구 수 = ${friends.length}');
        if (mounted) {
          setState(() {});
        }
      },
      onError: (error) => print('스트림 오류: $error'),
    );
  }

  void _showFilterBottomSheet() {
    FriendsFilterBottomSheet.show(
      context,
      currentFilters: _manager.selectedFilters,
      onFiltersApplied: (filters) {
        _manager.applyFilters(filters);
      },
    );
  }

  void _navigateToDetail(Map<String, dynamic> friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendsDetailPage(friends: friend),
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _manager,
      child: Consumer<FriendsStateManager>(
        builder: (context, manager, _) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _buildContainerDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(manager),
                _buildContent(manager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(FriendsStateManager manager) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: FriendsListHeader(
            onFilterTap: _showFilterBottomSheet,
            friendsCount: manager.displayFriends.length,
          ),
        ),
        SelectedFiltersDisplay(
          selectedFilters: manager.selectedFilters,
          onRemoveFilter: (category, option) {
            manager.removeFilter(category, option);
          },
        ),
      ],
    );
  }

  Widget _buildContent(FriendsStateManager manager) {
    if (manager.isLoading && manager.displayFriends.isEmpty) {
      return const FriendsLoadingSpinner();
    }

    if (manager.hasError && manager.displayFriends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            manager.errorMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      );
    }

    if (manager.displayFriends.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            '표시할 프렌즈가 없습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: manager.displayFriends.length,
          itemBuilder: (context, index) {
            final friend = manager.displayFriends[index];
            return Column(
              children: [
                if (index > 0) _buildDivider(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.only(
                    top: index == 0 ? 8 : 12,
                    bottom: 12,
                  ),
                  child: FriendsListItem(
                    friends: friend,
                    onTap: () => _navigateToDetail(friend),
                  ),
                ),
              ],
            );
          },
        ),
        if (manager.isLoading && manager.displayFriends.isNotEmpty)
          _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE4E4E4),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3182F6)),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        width: 1,
        color: const Color(0xFFE4E4E4),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}