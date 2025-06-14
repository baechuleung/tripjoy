import 'package:flutter/material.dart';
import '../services/reservation_info_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/custom_map.dart';

class MeetingPlaceInfoWidget extends StatelessWidget {
  final Map<String, dynamic> reservationData;
  final bool needLocationInput;
  final ReservationInfoService? infoService;
  final Function(Map<String, dynamic>? meetingPlace)? onUpdateLocation;
  final bool isEditable;
  final String? userId;
  final String? requestId;
  final VoidCallback? onLocationSelected;

  const MeetingPlaceInfoWidget({
    Key? key,
    required this.reservationData,
    this.needLocationInput = false,
    this.infoService,
    this.onUpdateLocation,
    this.isEditable = true,
    this.userId,
    this.requestId,
    this.onLocationSelected,
  }) : super(key: key);

  Future<void> showLocationPicker(BuildContext context) async {
    if (infoService == null) return;

    // 현재 meetingPlace 데이터가 있으면 가져오기
    LatLng? initialPosition;
    String? selectedAddress;

    if (reservationData.containsKey('meetingPlace') &&
        reservationData['meetingPlace'] is Map &&
        reservationData['meetingPlace'].isNotEmpty) {

      final locationData = reservationData['meetingPlace'] as Map;

      if (locationData.containsKey('latitude') &&
          locationData.containsKey('longitude')) {
        initialPosition = LatLng(
            locationData['latitude'],
            locationData['longitude']
        );
        selectedAddress = locationData['address'];
      }
    }

    // 모달 바텀시트로 지도 표시
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return CustomMap(
              initialPosition: initialPosition,
              selectedPosition: initialPosition,
              selectedAddress: selectedAddress,
              onLocationSelected: (position, address) {
                // 선택 후 데이터 저장
                reservationData['meetingPlace'] = {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'address': address,
                };

                Navigator.pop(context, true); // 성공 여부 반환
              },
            );
          },
        );
      },
    );

    if (result == true) {
      // meetingPlace 업데이트
      Map<String, dynamic>? meetingPlace = reservationData.containsKey('meetingPlace')
          ? Map<String, dynamic>.from(reservationData['meetingPlace'] as Map)
          : null;

      if (meetingPlace != null && userId != null && requestId != null) {
        try {
          final success = await infoService!.updateMeetingPlace(
            userId: userId!,
            requestId: requestId!,
            meetingPlace: meetingPlace,
          );

          if (success) {
            print('미팅 장소 업데이트 성공');
          } else {
            print('미팅 장소 업데이트 실패');
          }
        } catch (e) {
          print('미팅 장소 업데이트 중 오류 발생: $e');
        }
      }

      if (onUpdateLocation != null) {
        onUpdateLocation!(meetingPlace);
      }

      // 다음 단계로 자동 이동
      if (onLocationSelected != null) {
        onLocationSelected!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String meetingPlaceAddress = '';
    Color textColor = const Color(0xFF999999);

    if (reservationData.containsKey('meetingPlace') &&
        reservationData['meetingPlace'] is Map &&
        reservationData['meetingPlace'].containsKey('address') &&
        reservationData['meetingPlace']['address'] != null &&
        reservationData['meetingPlace']['address'].toString().isNotEmpty) {
      meetingPlaceAddress = reservationData['meetingPlace']['address'].toString();
      textColor = const Color(0xFF333333);
    } else if (needLocationInput) {
      meetingPlaceAddress = '약속장소를 선택해주세요.';
    }

    if (meetingPlaceAddress.isEmpty && !needLocationInput) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '약속장소',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          if (needLocationInput && infoService != null)
            InkWell(
              onTap: () => showLocationPicker(context),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: const Color(0xFFE4E4E4),
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '약속장소를 선택해주세요.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.search,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            )
          else if (meetingPlaceAddress.isNotEmpty && isEditable && infoService != null)
            InkWell(
              onTap: () => showLocationPicker(context),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meetingPlaceAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF237AFF),
                  ),
                ],
              ),
            )
          else if (meetingPlaceAddress.isNotEmpty)
              Text(
                meetingPlaceAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        ],
      ),
    );
  }
}