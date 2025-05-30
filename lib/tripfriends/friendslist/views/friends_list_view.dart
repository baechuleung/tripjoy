// lib/tripfriends/friendslist/views/friends_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/friends_list_controller.dart';
import '../filter/friends_filter_view.dart';
import '../filter/filter_constants.dart';
import '../../detail/friends_detail_page.dart';
import '../services/friends_list_manager.dart';
import '../widgets/friends_list_header.dart';
import '../widgets/selected_filters_display.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/friends_list_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsListView extends StatefulWidget {
  final List<String>? friendUserIds;
  final bool preserveState;

  const FriendsListView({
    super.key,
    this.friendUserIds,
    this.preserveState = true,
  });

  @override
  State<FriendsListView> createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FriendsListManager _manager = FriendsListManager();

  bool _isFilterApplied = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _currentFriends = [];
  List<Map<String, dynamic>> _displayFriends = [];
  Stream<List<Map<String, dynamic>>>? _friendsStream;

  @override
  void initState() {
    super.initState();

    // 전역 컨트롤러 초기화
    if (globalFriendsListController == null) {
      globalFriendsListController = FriendsListController();
      globalFriendsListController!.initialize();
    }

    globalFriendsListController!.preserveStateOnReset = true;
    _manager.setShuffleEnabled(true);

    _checkFilterStatus();

    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _checkFilterStatus() {
    _isFilterApplied = _manager.hasActiveFilters(
        globalFriendsListController!.selectedFilters
    );
  }

  Future<void> _loadInitialData() async {
    try {
      // plan_request 정보 로드
      final requestInfo = await _manager.loadPlanRequest();

      // 컨트롤러에 위치 정보 설정
      globalFriendsListController!.setLocationInfo(
          requestInfo['city'],
          requestInfo['nationality']
      );

      // 데이터 로드
      await _loadFriendsData();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _loadFriendsData() async {
    final requestDocId = _manager.requestDocId;
    final requestCity = _manager.requestCity;
    final requestNationality = _manager.requestNationality;

    if (requestDocId == null || requestCity == null || requestNationality == null) {
      return;
    }

    final cacheKey = widget.friendUserIds != null ? 'specific' : 'general';

    try {
      if (widget.friendUserIds != null) {
        // 특정 친구 목록
        final friends = await _manager.dataService.loadMoreFriendsWithIds(
            widget.friendUserIds!,
            {'city': requestCity, 'nationality': requestNationality},
            requestDocId,
            cacheKey,
            forceRefresh: true
        );

        _updateFriendsList(friends);
      } else {
        // 일반 친구 목록 - 스트림 방식
        final query = FirebaseFirestore.instance
            .collection('tripfriends_users')
            .where('location.city', isEqualTo: requestCity)
            .where('location.nationality', isEqualTo: requestNationality);

        _friendsStream = _manager.dataService.loadFriendsStream(
            query,
            requestDocId,
            cacheKey,
            forceRefresh: true
        );

        // 스트림 리스너 설정
        _friendsStream!.listen((friends) {
          if (mounted) {
            _updateFriendsList(friends);
          }
        }, onError: (error) {
          debugPrint('❌ 스트림 오류: $error');
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다.';
          });
        });
      }

    } catch (e) {
      debugPrint('❌ 친구 데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  void _updateFriendsList(List<Map<String, dynamic>> friends) {
    setState(() {
      _currentFriends = friends;
      _applyFiltersToFriends();
      _isLoading = false;
    });
  }

  void _applyFiltersToFriends() {
    if (_currentFriends.isEmpty) {
      _displayFriends = [];
      _hasError = true;
      _errorMessage = '현재 추천할 프렌즈가 없습니다.';
      return;
    }

    // 통합 관리자를 통해 친구 목록 처리
    _displayFriends = _manager.processFriendsList(_currentFriends);

    _hasError = _displayFriends.isEmpty;
    if (_hasError) {
      _errorMessage = '필터 조건에 맞는 프렌즈가 없습니다.';
    }

    debugPrint('📊 친구 목록 상태: 전체 ${_currentFriends.length}명, 표시 ${_displayFriends.length}명');
  }

  void _showFilterBottomSheet() {
    FriendsFilter.showFilterBottomSheet(
        context,
            (query, selectedFilters) async {
          final hasActiveFilters = _manager.hasActiveFilters(selectedFilters);
          final hasSortingFilter = _manager.hasSortingFilter(selectedFilters);

          // 정렬 필터가 있으면 셔플 비활성화
          _manager.setShuffleEnabled(!hasSortingFilter);

          await globalFriendsListController!.applyFilters(query, selectedFilters);

          if (mounted) {
            setState(() {
              _isFilterApplied = hasActiveFilters;
              _applyFiltersToFriends();
            });
          }
        },
        globalFriendsListController!.selectedFilters
    );
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> friends) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendsDetailPage(friends: friends),
        maintainState: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider.value(
      value: globalFriendsListController,
      child: Consumer<FriendsListController>(
        builder: (context, controller, _) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Color(0xFFE4E4E4)),
                borderRadius: BorderRadius.circular(12),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    // 헤더는 항상 위쪽 패딩 유지
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FriendsListHeader(
                        onFilterTap: _showFilterBottomSheet,
                        friendsCount: _displayFriends.length,
                      ),
                    ),

                    SelectedFiltersDisplay(
                      selectedFilters: controller.selectedFilters,
                      onRemoveFilter: (category, option) {
                        controller.removeFilter(category, option);

                        // 모든 필터가 제거되었는지 확인
                        final hasActiveFilters = _manager.hasActiveFilters(
                            controller.selectedFilters
                        );

                        // 정렬 필터가 있는지 확인
                        final hasSortingFilter = _manager.hasSortingFilter(
                            controller.selectedFilters
                        );

                        // 셔플 상태 업데이트
                        _manager.setShuffleEnabled(!hasSortingFilter);

                        setState(() {
                          _isFilterApplied = hasActiveFilters;
                          _applyFiltersToFriends();
                        });
                      },
                    ),

                    if (_isLoading && _currentFriends.isEmpty) ...[
                      const FriendsLoadingSpinner(),
                    ] else if (_hasError && _displayFriends.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // 친구 목록 표시
                      if (_displayFriends.isNotEmpty) ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16), // 하단 패딩만 유지
                          itemCount: _displayFriends.length,
                          itemBuilder: (context, index) {
                            final friend = _displayFriends[index];
                            return Column(
                              children: [
                                // 첫 번째 아이템 위에는 divider 없음
                                if (index > 0)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 32),
                                    child: Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFE4E4E4),
                                    ),
                                  ),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: EdgeInsets.only(
                                    top: index == 0 ? 8 : 12, // 첫 번째 아이템은 위 패딩 줄임
                                    bottom: 12,
                                  ),
                                  child: FriendsListItem(
                                    friends: friend,
                                    onTap: () => _navigateToDetail(context, friend),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],

                      // 로딩 중 표시 (데이터가 있을 때)
                      if (_isLoading && _currentFriends.isNotEmpty) ...[
                        const Padding(
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
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}