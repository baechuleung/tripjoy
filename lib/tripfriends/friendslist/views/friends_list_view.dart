// lib/tripfriends/friendslist/views/friends_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/friends_list_controller.dart';
import '../filter/friends_filter_view.dart';
import '../filter/filter_constants.dart';
import '../../detail/friends_detail_page.dart';
import '../services/random_shuffle_service.dart';
import '../filter/friends_filter_service.dart';
import '../services/friends_data_service.dart';
import '../services/friends_data_service.dart';
import '../widgets/friends_list_header.dart';
import '../widgets/selected_filters_display.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/friends_list_item.dart';
import '../services/friends_request_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final FriendsFilterService _filterService = FriendsFilterService();
  final RandomShuffleService _shuffleService = RandomShuffleService();
  final FriendsDataService _dataService = FriendsDataService();

  bool _isFilterApplied = false;
  int _forceRefreshCounter = 0;
  String? _requestCity;
  String? _requestNationality;
  String? _requestDocId;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _currentFriends = [];
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
    _shuffleService.shuffleEnabled = true;

    _checkFilterStatus();

    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _checkFilterStatus() {
    bool hasActiveFilters = false;

    for (var category in globalFriendsListController!.selectedFilters.keys) {
      if (globalFriendsListController!.selectedFilters[category]!.isNotEmpty &&
          !globalFriendsListController!.selectedFilters[category]!.contains('상관없음') &&
          !globalFriendsListController!.selectedFilters[category]!.contains('전체')) {
        hasActiveFilters = true;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _isFilterApplied = hasActiveFilters;
      });
    }
  }

  Future<void> _loadInitialData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '로그인이 필요합니다.';
      });
      return;
    }

    try {
      // plan_requests 정보 가져오기
      final requestSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('plan_requests')
          .limit(1)
          .get();

      if (requestSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '여행 요청 정보가 없습니다.';
        });
        return;
      }

      final requestDoc = requestSnapshot.docs.first;
      _requestDocId = requestDoc.id;
      final requestData = requestDoc.data();

      if (requestData['location'] is Map) {
        final location = Map<String, dynamic>.from(requestData['location'] as Map);
        _requestCity = location['city'] as String?;
        _requestNationality = location['nationality'] as String?;

        _filterService.setLocationFilter(_requestCity, _requestNationality);
        globalFriendsListController!.setLocationInfo(_requestCity, _requestNationality);
      }

      if (_requestCity == null || _requestNationality == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '여행 요청의 위치 정보가 불완전합니다.';
        });
        return;
      }

      // 데이터 로드
      await _loadFriendsData();

    } catch (e) {
      debugPrint('⚠️ 초기 데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  Future<void> _loadFriendsData() async {
    if (_requestDocId == null || _requestCity == null || _requestNationality == null) {
      return;
    }

    final cacheKey = widget.friendUserIds != null ? 'specific' : 'general';

    try {
      if (widget.friendUserIds != null) {
        // 특정 친구 목록은 기존 방식 유지
        final friends = await _dataService.loadMoreFriendsWithIds(
            widget.friendUserIds!,
            {'city': _requestCity, 'nationality': _requestNationality},
            _requestDocId!,
            cacheKey,
            forceRefresh: true
        );

        setState(() {
          _currentFriends = friends;
          _isLoading = false;
          _hasError = friends.isEmpty;
          if (_hasError) {
            _errorMessage = '현재 추천할 프렌즈가 없습니다.';
          }
        });
      } else {
        // 일반 친구 목록은 스트림 방식
        final query = FirebaseFirestore.instance
            .collection('tripfriends_users')
            .where('location.city', isEqualTo: _requestCity)
            .where('location.nationality', isEqualTo: _requestNationality)
            .where('isActive', isEqualTo: true)
            .where('isApproved', isEqualTo: true);

        _friendsStream = _dataService.loadFriendsStream(
            query,
            _requestDocId!,
            cacheKey,
            forceRefresh: true
        );

        // 스트림 리스너 설정
        _friendsStream!.listen((friends) {
          if (mounted) {
            setState(() {
              _currentFriends = friends;
              _isLoading = false;
              _hasError = false;
            });
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

  void _showFilterBottomSheet() {
    if (_requestCity != null && _requestNationality != null) {
      _filterService.setLocationFilter(_requestCity, _requestNationality);
    }

    FriendsFilter.showFilterBottomSheet(
        context,
            (query, selectedFilters) async {
          bool hasActiveFilters = false;
          bool hasRatingFilter = false;
          bool hasMatchCountFilter = false;

          for (var category in selectedFilters.keys) {
            if (selectedFilters[category]!.isNotEmpty &&
                !selectedFilters[category]!.contains('상관없음') &&
                !selectedFilters[category]!.contains('전체')) {
              hasActiveFilters = true;
            }

            if (category == FilterConstants.RATING &&
                selectedFilters[category]!.isNotEmpty &&
                !selectedFilters[category]!.contains('상관없음')) {
              hasRatingFilter = true;
            }

            if (category == FilterConstants.MATCH_COUNT &&
                selectedFilters[category]!.isNotEmpty &&
                !selectedFilters[category]!.contains('상관없음')) {
              hasMatchCountFilter = true;
            }
          }

          _shuffleService.shuffleEnabled = !(hasRatingFilter || hasMatchCountFilter);
          _shuffleService.clearAllCache();

          await globalFriendsListController!.applyFilters(query, selectedFilters);

          if (mounted) {
            setState(() {
              _isFilterApplied = hasActiveFilters;
              _forceRefreshCounter++;
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

  Widget _buildFriendItem(Map<String, dynamic> friend, FriendsListController controller) {
    // 필터 적용
    final filteredList = _filterService.applyClientSideFilters([friend]);
    if (filteredList.isEmpty) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: FriendsListItem(
        friends: friend,
        onTap: () => _navigateToDetail(context, friend),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      FriendsListHeader(
                        onFilterTap: _showFilterBottomSheet,
                        friendsCount: _currentFriends.length,
                      ),

                      SelectedFiltersDisplay(
                        selectedFilters: controller.selectedFilters,
                        onRemoveFilter: controller.removeFilter,
                      ),

                      if (_isLoading && _currentFriends.isEmpty) ...[
                        const FriendsLoadingSpinner(),
                      ] else if (_hasError && _currentFriends.isEmpty) ...[
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
                        // 실시간으로 추가되는 친구 목록
                        if (_currentFriends.isNotEmpty) ...[
                          AnimatedList(
                            key: GlobalKey<AnimatedListState>(),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            initialItemCount: _currentFriends.length,
                            itemBuilder: (context, index, animation) {
                              if (index >= _currentFriends.length) return Container();

                              final friend = _currentFriends[index];
                              return SlideTransition(
                                position: animation.drive(
                                  Tween(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ).chain(CurveTween(curve: Curves.easeOut)),
                                ),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildFriendItem(friend, controller),
                                  ),
                                ),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}