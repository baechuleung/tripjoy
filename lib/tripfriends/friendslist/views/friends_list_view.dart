// lib/tripfriends/friendslist/views/friends_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../core/friends_state_manager.dart';
import '../widgets/friends_list_header.dart';
import '../widgets/selected_filters_display.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/friends_list_item.dart';
import '../../detail/screens/friends_detail_page.dart';
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
  FriendsStateManager? _manager;
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(FriendsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // friendUserIds가 변경되면 다시 로드
    if (oldWidget.friendUserIds != widget.friendUserIds) {
      _loadData();
    }
  }

  void _loadData() {
    print('🔄 FriendsListView: 데이터 로드 시작');

    // 기존 정리
    _streamSubscription?.cancel();
    _manager?.dispose();

    // 새로 생성 - 매번 새로!
    _manager = FriendsStateManager();

    // 먼저 UI 갱신하여 이전 데이터가 표시되지 않도록 함
    if (mounted) {
      setState(() {});
    }

    // 스트림 시작
    _streamSubscription = _manager!.loadFriendsStream().listen(
          (friends) {
        if (mounted) {
          setState(() {});
        }
      },
      onError: (error) => print('스트림 오류: $error'),
    );
  }

  void _showFilterBottomSheet() {
    if (_manager == null) return;

    FriendsFilterBottomSheet.show(
      context,
      currentFilters: _manager!.selectedFilters,
      onFiltersApplied: (filters) {
        _manager!.applyFilters(filters);
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
    _manager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_manager == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ChangeNotifierProvider.value(
      value: _manager!,
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
    // 로딩 중이고 데이터가 비어있을 때만 로딩 스피너 표시
    if (manager.isLoading && manager.displayFriends.isEmpty) {
      return const FriendsLoadingSpinner();
    }

    // 에러가 있고 데이터가 없을 때
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

    // 로딩이 끝났는데 데이터가 없을 때
    if (!manager.isLoading && manager.displayFriends.isEmpty) {
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

    // 데이터가 있으면 Grid 표시
    if (manager.displayFriends.isNotEmpty) {
      return Column(
        children: [
          // GridView를 수동으로 구성
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // 첫 번째 줄 (0-2 인덱스)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // 추가: 상단 정렬
                  children: List.generate(
                    3,
                        (index) {
                      if (index < manager.displayFriends.length) {
                        final friend = manager.displayFriends[index];
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 5,
                              right: index == 2 ? 0 : 5,
                            ),
                            child: AspectRatio(
                              aspectRatio: 0.60,
                              child: FriendsListItem(
                                friends: friend,
                                onTap: () => _navigateToDetail(friend),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Expanded(child: Container());
                      }
                    },
                  ),
                ),

                // 나머지 아이템들 (3번 인덱스부터)
                if (manager.displayFriends.length > 3)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: manager.displayFriends.length - 3,
                    itemBuilder: (context, index) {
                      final friend = manager.displayFriends[index + 3];
                      return FriendsListItem(
                        friends: friend,
                        onTap: () => _navigateToDetail(friend),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // 기본적으로 빈 컨테이너 반환
    return const SizedBox.shrink();
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