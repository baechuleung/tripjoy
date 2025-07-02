// lib/point_module/widgets/history_tab_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryTabView extends StatefulWidget {
  const HistoryTabView({super.key});

  @override
  State<HistoryTabView> createState() => _HistoryTabViewState();
}

class _HistoryTabViewState extends State<HistoryTabView> {
  String _selectedFilter = '전체';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final numberFormat = NumberFormat('#,###');

    if (currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('points_history')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              '포인트 사용 내역이 없습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          );
        }

        // 필터링된 데이터
        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = data['amount'] ?? 0;

          if (_selectedFilter == '전체') return true;
          if (_selectedFilter == '충전') return amount > 0;
          if (_selectedFilter == '사용') return amount < 0;
          return true;
        }).toList();

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // 필터 버튼
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildFilterButton('전체'),
                    const SizedBox(width: 8),
                    _buildFilterButton('충전'),
                    const SizedBox(width: 8),
                    _buildFilterButton('사용'),
                  ],
                ),
              ),
              // 리스트
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: filteredDocs.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: Color(0xFFECECEC),
                        thickness: 1,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final amount = data['amount'] ?? 0;
                        final isCharge = amount > 0;
                        final timestamp = data['createdAt'] as Timestamp?;
                        final date = timestamp?.toDate() ?? DateTime.now();

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('yyyy.MM.dd HH:mm').format(date),
                                    style: const TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['description'] ?? (isCharge ? '포인트 충전' : '포인트 사용'),
                                    style: const TextStyle(
                                      color: Color(0xFF4E5968),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${isCharge ? '+' : ''}${numberFormat.format(amount)} P',
                                style: TextStyle(
                                  color: isCharge ? const Color(0xFF3182F6) : const Color(0xFF999999),
                                  fontSize: 16,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  height: isCharge ? null : 1.20,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(String text) {
    final isSelected = _selectedFilter == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
      },
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFF4047ED) : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: isSelected
                ? BorderSide.none
                : const BorderSide(
              width: 1,
              color: Color(0xFFE2E2E2),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF353535),
              fontSize: 13,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}