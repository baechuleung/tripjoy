import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'review_item_widget.dart';
import 'package:tripjoy/components/tripfriends_bottom_navigator.dart';

class ReviewPage extends StatefulWidget {
  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedLocation = '전체';
  bool _isLoading = false;
  Map<String, String> _countryCodeToName = {};
  Map<String, String> _cityCodeToName = {}; // 도시 코드를 이름으로 변환하는 맵
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCountryData();
  }

  Future<void> _loadCountryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // country.json 파일 로드
      final String response = await rootBundle.loadString('assets/data/country.json');
      final data = await json.decode(response);

      // 국가 코드를 한국어 이름으로 매핑
      for (var country in data['countries']) {
        String code = country['code'];
        String koreanName = country['names']['KR'];
        _countryCodeToName[code] = koreanName;

        // 해당 국가의 도시 데이터 로드 시도
        try {
          final String cityResponse = await rootBundle.loadString('assets/data/city/${code}.json');
          final cityData = await json.decode(cityResponse);

          // 각 도시의 코드와 이름을 매핑
          for (var city in cityData) {
            if (city['code'] != null && city['name'] != null) {
              _cityCodeToName[city['code']] = city['name'];
            }
          }
        } catch (e) {
          print('도시 데이터 로드 오류 (${code}): $e');
        }
      }
    } catch (e) {
      print('국가 데이터 로드 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 국가 코드를 한국어 이름으로 변환하는 함수
  String _getCountryName(String code) {
    return _countryCodeToName[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Color(0xFFF9F9F9),
        appBar: AppBar(
          title: Text('내 리뷰', style: TextStyle(color: Colors.black, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: TripfriendsBottomNavigator(
          currentIndex: 2,
          onTap: (index) {},
          scaffoldKey: _scaffoldKey,
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('내 리뷰',style: TextStyle(color: Color(0xFF353535),fontSize: 16,fontWeight: FontWeight.w600,),),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 단순화된 쿼리 - 모든 리뷰를 가져온 후 클라이언트에서 필터링
        stream: FirebaseFirestore.instance
            .collectionGroup('reviews')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Firestore Error Details: ${snapshot.error}');
            print('Error Stack Trace: ${snapshot.stackTrace}');
            return Center(child: Text('오류가 발생했습니다'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // tripfriends_users 경로에 있는 문서만 필터링
          final allReviews = snapshot.data?.docs.where((doc) {
            return doc.reference.path.contains('tripfriends_users/');
          }).toList() ?? [];

          // 클라이언트 측에서 선택된 위치에 따라 필터링
          final reviews = _selectedLocation == '전체'
              ? allReviews
              : allReviews.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['location'] != null && data['location'] is Map) {
              final location = data['location'] as Map<String, dynamic>;
              if (location['nationality'] != null && location['nationality'] is String) {
                String nationCode = location['nationality'] as String;
                String countryName = _getCountryName(nationCode);
                return countryName == _selectedLocation;
              }
            }
            return false;
          }).toList();

          print('필터링된 리뷰 개수: ${reviews.length}');

          Set<String> countryNames = {'전체'};

          // 국가 정보 수집
          for (var doc in allReviews) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['location'] != null && data['location'] is Map) {
              final location = data['location'] as Map<String, dynamic>;
              if (location['nationality'] != null && location['nationality'] is String) {
                String nationCode = location['nationality'] as String;
                String countryName = _getCountryName(nationCode);
                countryNames.add(countryName);
              }
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 32, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내가 작성한 리뷰 ${reviews.length}개',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: countryNames.map((countryName) {
                          bool isSelected = _selectedLocation == countryName;
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedLocation = countryName;
                                });
                                print('선택된 위치: $_selectedLocation');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Color(0xFF3182F6) : Colors.white,
                                foregroundColor: isSelected ? Colors.white : Colors.black,
                                elevation: 0,
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(countryName),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: reviews.isEmpty
                    ? Center(child: Text('작성한 리뷰가 없습니다.'))
                    : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final doc = reviews[index];
                    final review = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ReviewItemWidget(
                        review: review,
                        doc: doc,
                        countryCodeToName: _countryCodeToName,
                        cityCodeToName: _cityCodeToName,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: TripfriendsBottomNavigator(
        currentIndex: 2,
        onTap: (index) {},
        scaffoldKey: _scaffoldKey,
      ),
    );
  }
}