import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class CustomMap extends StatefulWidget {
  final LatLng? initialPosition;
  final LatLng? selectedPosition;
  final String? selectedAddress;
  final Function(LatLng position, String address) onLocationSelected;

  const CustomMap({
    super.key,
    this.initialPosition,
    this.selectedPosition,
    this.selectedAddress,
    required this.onLocationSelected,
  });

  @override
  State<CustomMap> createState() => _CustomMapState();
}

class _CustomMapState extends State<CustomMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng _center = const LatLng(37.5665, 126.9780);
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isDragging = false;
  String? _currentAddress;
  LatLng? _currentPosition;
  bool _isAddressLoading = false;
  bool _isGettingLocation = false;

  static const String _apiKey = 'AIzaSyAAfi5e2l_0DmWBiwIWqB7kKyzj9uiHlGk';

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _center = widget.initialPosition!;
    }
    if (widget.selectedPosition != null) {
      _currentPosition = widget.selectedPosition;
      _currentAddress = widget.selectedAddress;
      _addMarker(widget.selectedPosition!, widget.selectedAddress ?? '선택된 위치');
    }
  }

  Future<void> _searchPlaces(String query) async {
    debugPrint('검색 시작: $query');

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/place/textsearch/json'
                '?query=$query'
                '&location=${_center.latitude},${_center.longitude}'
                '&radius=50000'
                '&language=ko'
                '&region=kr'
                '&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = (data['results'] as List)
              .take(10)
              .map((place) => PlaceSearchResult(
            name: place['name'] as String,
            address: place['formatted_address'] as String,
            position: LatLng(
              place['geometry']['location']['lat'] as double,
              place['geometry']['location']['lng'] as double,
            ),
          ))
              .toList();

          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        } else {
          debugPrint('Places API Error: ${data['status']}');
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('장소 검색 중 오류 발생: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _addMarker(LatLng position, String title) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(title: title),
        ),
      };
    });
  }

  Future<void> _getAddressFromPosition(LatLng position) async {
    if (_isAddressLoading) return;

    setState(() {
      _isAddressLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json'
                '?latlng=${position.latitude},${position.longitude}'
                '&language=ko'
                '&result_type=street_address|premise|subpremise'
                '&key=$_apiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'] as String;

          setState(() {
            _currentPosition = position;
            _currentAddress = address;
            _isAddressLoading = false;
          });

          _addMarker(position, address);
        } else {
          final backupResponse = await http.get(
            Uri.parse(
                'https://maps.googleapis.com/maps/api/geocode/json'
                    '?latlng=${position.latitude},${position.longitude}'
                    '&language=ko'
                    '&key=$_apiKey'
            ),
          );

          final backupData = json.decode(backupResponse.body);
          if (backupData['status'] == 'OK' && backupData['results'].isNotEmpty) {
            final address = backupData['results'][0]['formatted_address'] as String;

            setState(() {
              _currentPosition = position;
              _currentAddress = address;
              _isAddressLoading = false;
            });

            _addMarker(position, address);
          } else {
            throw Exception('주소를 찾을 수 없습니다');
          }
        }
      } else {
        throw Exception('API 응답 오류');
      }
    } catch (e) {
      debugPrint('주소 검색 중 오류 발생: $e');
      setState(() {
        _currentPosition = position;
        _currentAddress = '선택된 위치';
        _isAddressLoading = false;
      });
      _addMarker(position, '선택된 위치');
    }
  }

  void _handleMapTap(LatLng position) {
    _getAddressFromPosition(position);
  }

  void _moveToLocation(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 17),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.')),
          );
          setState(() {
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.')),
        );
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentPosition = LatLng(position.latitude, position.longitude);

      _moveToLocation(currentPosition);
      _getAddressFromPosition(currentPosition);

      setState(() {
        _isGettingLocation = false;
      });

    } catch (e) {
      debugPrint('현재 위치 가져오기 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 가져오는데 실패했습니다. 다시 시도해주세요.')),
      );
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '만남 장소 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),

          // 지도 영역
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onTap: _handleMapTap,
                  onCameraMoveStarted: () {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onCameraMove: (position) {
                    _center = position.target;
                  },
                  onCameraIdle: () {
                    setState(() {
                      _isDragging = false;
                    });
                    _getAddressFromPosition(_center);
                  },
                ),

                // 드래그 중 표시되는 중앙 마커
                if (_isDragging)
                  const Center(
                    child: Icon(
                      Icons.location_pin,
                      color: Color(0xFF237AFF),
                      size: 40,
                    ),
                  ),

                // 검색창과 결과 리스트
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '장소를 검색하세요',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _isSearching = false;
                                    _searchResults = [];
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) => _searchPlaces(value),
                          ),
                        ),

                        // 선택된 위치 표시
                        if (_markers.isNotEmpty && !_isSearching)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF237AFF),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isAddressLoading
                                        ? '주소 정보를 가져오는 중...'
                                        : (_markers.first.infoWindow.title ?? '선택된 위치'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: CircularProgressIndicator(),
                          ),

                        // 검색 결과 리스트
                        if (_isSearching && _searchResults.isNotEmpty)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final result = _searchResults[index];
                                    return ListTile(
                                      title: Text(
                                        result.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        result.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      dense: true,
                                      onTap: () {
                                        _moveToLocation(result.position);
                                        setState(() {
                                          _currentPosition = result.position;
                                          _currentAddress = result.address;
                                        });
                                        _addMarker(result.position, result.address);
                                        _searchController.clear();
                                        setState(() {
                                          _isSearching = false;
                                          _searchResults = [];
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 커스텀 지도 컨트롤 버튼들
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 현재 위치 버튼
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: _isGettingLocation
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF237AFF),
                            ),
                          )
                              : const Icon(Icons.my_location, color: Colors.black87),
                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                        ),
                      ),

                      // 줌 인 버튼
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.black87),
                          onPressed: () {
                            _mapController?.animateCamera(CameraUpdate.zoomIn());
                          },
                        ),
                      ),

                      // 줌 아웃 버튼
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.remove, color: Colors.black87),
                          onPressed: () {
                            _mapController?.animateCamera(CameraUpdate.zoomOut());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 하단 확인 버튼
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentPosition != null && !_isAddressLoading
                    ? () {
                  widget.onLocationSelected(
                    _currentPosition!,
                    _currentAddress ?? '선택된 위치',
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF237AFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isAddressLoading ? '주소 정보를 가져오는 중...' : '위치 선택 완료',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

class PlaceSearchResult {
  final String name;
  final String address;
  final LatLng position;

  PlaceSearchResult({
    required this.name,
    required this.address,
    required this.position,
  });
}