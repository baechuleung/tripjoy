// lib/tripfriends/friendslist/filter/friends_filter_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/translation_service.dart';
import 'friends_filter_service.dart';
import 'filter_constants.dart';

class FriendsFilter extends StatefulWidget {
  final Function(Query) onFilterChanged;

  const FriendsFilter({
    super.key,
    required this.onFilterChanged,
  });

  // 외부에서 호출 가능하도록 static 메서드 추가
  static void showFilterBottomSheet(
      BuildContext context,
      Function(Query, Map<String, Set<String>>) onFilterApplied,
      [Map<String, Set<String>>? currentFilters]) {

    // 공유 필터 서비스 인스턴스
    final filterService = FriendsFilterService();

    // 현재 선택된 필터 상태를 서비스에 설정 (중요!)
    if (currentFilters != null) {
      filterService.setFilters(currentFilters);
    }

    _showFilterBottomSheet(context, filterService, onFilterApplied);
  }

  // 바텀시트 표시 - 필터 서비스 사용
  static void _showFilterBottomSheet(
      BuildContext context,
      FriendsFilterService filterService,
      Function(Query, Map<String, Set<String>>) onFilterApplied
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 필터 옵션 가져오기
            final filterOptions = FilterConstants.filterOptions;
            if (filterOptions.isEmpty) {
              return const Center(child: Text('필터 옵션을 불러오는 중...'));
            }

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
                  // 상단 바 (드래그 핸들)
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 필터 제목
                  Padding(
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
                          onPressed: () {
                            setModalState(() {
                              filterService.resetFilters();
                            });
                          },
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
                  ),

                  const Divider(),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: filterOptions.entries.map((entry) {
                            String category = entry.key;
                            List<String> options = entry.value;

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
                                    // 현재 선택 상태 확인
                                    bool isSelected = filterService.selectedFilters[category]?.contains(option) ?? false;

                                    return FilterChip(
                                      label: Text(option),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setModalState(() {
                                          // 필터 토글 - 이 부분이 UI에 즉시 반영됨
                                          filterService.toggleFilter(category, option, selected);
                                        });
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: Colors.blue.shade100,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: BorderSide(
                                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                                        ),
                                      ),
                                      showCheckmark: false, // 체크마크 제거
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // 하단 버튼 영역
                  Container(
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
                      onTap: () async {
                        // 필터 적용
                        Query query = filterService.applyFilters();

                        // 현재 필터 상태 가져오기 (복사본)
                        final selectedFiltersCopy = filterService.getFiltersCopy();

                        // 바텀시트 닫기
                        Navigator.pop(context);

                        // 콜백 호출 - 선택된 필터와 쿼리 함께 전달
                        onFilterApplied(query, selectedFiltersCopy);
                      },
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
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<FriendsFilter> createState() => _FriendsFilterState();
}

class _FriendsFilterState extends State<FriendsFilter> {
  final TranslationService _translationService = TranslationService();
  final FriendsFilterService _filterService = FriendsFilterService();
  bool _isTranslationsLoaded = false;
  bool _isDisposed = false;

  // 현재 적용된 필터를 저장하는 변수 추가
  Map<String, Set<String>> _currentAppliedFilters = {};

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 초기 필터 적용
    Future.microtask(() => _applyFilters());
  }

  Future<void> _loadTranslations() async {
    if (_isDisposed) return;
    await _translationService.loadTranslations();
    if (mounted && !_isDisposed) {
      setState(() {
        _isTranslationsLoaded = true;
      });
    }
  }

  void _applyFilters() {
    // 필터 서비스에서 필터 적용하여 쿼리 가져오기
    Query query = _filterService.applyFilters();

    // 현재 필터 상태 저장
    _currentAppliedFilters = _filterService.getFiltersCopy();

    // 필터 변경 콜백 호출
    widget.onFilterChanged(query);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return Container();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // 필터 버튼 (바텀시트 열기)
          GestureDetector(
            onTap: () {
              // 필터 적용 콜백 함수
              void onFilterApplied(Query query, Map<String, Set<String>> filters) {
                if (!_isDisposed) {
                  setState(() {
                    // 현재 적용된 필터 업데이트
                    _currentAppliedFilters = filters;
                  });

                  // 콜백 호출
                  widget.onFilterChanged(query);
                }
              }

              // 저장된 현재 필터 사용
              FriendsFilter.showFilterBottomSheet(
                context,
                onFilterApplied,
                _currentAppliedFilters,  // 저장된 현재 필터 전달
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '필터',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}