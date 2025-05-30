import 'package:flutter/material.dart';
import 'services/reservation_service.dart';
import 'services/reservation_info_service.dart';
import 'widgets/meeting_place_info_widget.dart';
import 'widgets/scheduled_date_widget.dart';
import 'widgets/start_time_widget.dart';
import 'widgets/person_count_widget.dart';
import 'widgets/location_info_widget.dart';
import 'widgets/purpose_widget.dart';

class ReservationInfoSection extends StatefulWidget {
  final Map<String, dynamic> reservationData;
  final ReservationService reservationService;
  final Function onUpdateUI;
  final bool needLocationInput;
  final String userId;
  final String requestId;

  const ReservationInfoSection({
    super.key,
    required this.reservationData,
    required this.reservationService,
    required this.onUpdateUI,
    required this.needLocationInput,
    required this.userId,
    required this.requestId,
  });

  @override
  State<ReservationInfoSection> createState() => _ReservationInfoSectionState();
}

class _ReservationInfoSectionState extends State<ReservationInfoSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartSequentialSelection();
    });
  }

  void _checkAndStartSequentialSelection() {
    if (!widget.reservationData.containsKey('useDate') ||
        widget.reservationData['useDate'] == null ||
        widget.reservationData['useDate'].toString().isEmpty) {
      _showDatePicker();
    }
    else if (!widget.reservationData.containsKey('startTime') ||
        widget.reservationData['startTime'] == null ||
        widget.reservationData['startTime'].toString().isEmpty) {
      _showTimePicker();
    }
    else if (!widget.reservationData.containsKey('personCount') ||
        widget.reservationData['personCount'] == null ||
        widget.reservationData['personCount'] <= 0) {
      _showPersonPicker();
    }
    else if (widget.reservationService.isMeetingPlaceEmpty(widget.reservationData)) {
      _showLocationPicker();
    }
    else if (widget.reservationService.isPurposeEmpty(widget.reservationData)) {
      _showPurposePicker();
    }
  }

  void _showDatePicker() async {
    await Future.delayed(Duration(milliseconds: 100));

    final dateWidget = ScheduledDateWidget(
      reservationData: widget.reservationData,
      reservationService: widget.reservationService,
      onUpdateUI: widget.onUpdateUI as VoidCallback,
      onDateSelected: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTimePicker();
        });
      },
    );

    await dateWidget.showDatePicker(context);
  }

  void _showTimePicker() async {
    await Future.delayed(Duration(milliseconds: 100));

    final timeWidget = StartTimeWidget(
      reservationData: widget.reservationData,
      onUpdateUI: widget.onUpdateUI as VoidCallback,
      onTimeCompleted: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPersonPicker();
        });
      },
    );

    await timeWidget.showTimeSelector(context);
  }

  void _showPersonPicker() async {
    await Future.delayed(Duration(milliseconds: 100));

    final personWidget = PersonCountWidget(
      reservationData: widget.reservationData,
      onUpdateUI: widget.onUpdateUI as VoidCallback,
      onPersonSelected: () {
        // 약속장소 선택으로 이동
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLocationPicker();
        });
      },
    );

    await personWidget.showPersonSelector(context);
  }

  void _showLocationPicker() async {
    await Future.delayed(Duration(milliseconds: 100));

    final locationWidget = MeetingPlaceInfoWidget(
      reservationData: widget.reservationData,
      needLocationInput: true,
      infoService: ReservationInfoService(),
      onUpdateLocation: (meetingPlace) {
        widget.onUpdateUI();
      },
      isEditable: true,
      userId: widget.userId,
      requestId: widget.requestId,
      onLocationSelected: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPurposePicker();
        });
      },
    );

    await locationWidget.showLocationPicker(context);
  }

  void _showPurposePicker() async {
    await Future.delayed(Duration(milliseconds: 100));

    final purposeWidget = PurposeWidget(
      reservationData: widget.reservationData,
      onUpdateUI: widget.onUpdateUI as VoidCallback,
      onPurposeSelected: () {
        widget.onUpdateUI();
      },
    );

    await purposeWidget.showPurposeSelector(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '예약 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (widget.reservationData.containsKey('reservationNumber'))
                Text(
                  '예약번호: ${widget.reservationData['reservationNumber']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 20),

          if (widget.reservationData.containsKey('location'))
            LocationInfoWidget(
              locationData: widget.reservationData['location'],
            ),

          ScheduledDateWidget(
            reservationData: widget.reservationData,
            reservationService: widget.reservationService,
            onUpdateUI: () => widget.onUpdateUI(),
            // 값이 비어있을 때만 자동으로 다음 단계로
            onDateSelected: (!widget.reservationData.containsKey('useDate') ||
                widget.reservationData['useDate'] == null ||
                widget.reservationData['useDate'].toString().isEmpty)
                ? () => _showTimePicker()
                : null,
          ),

          StartTimeWidget(
            reservationData: widget.reservationData,
            needTimeInput: true,
            onUpdateUI: () => widget.onUpdateUI(),
            // 값이 비어있을 때만 자동으로 다음 단계로
            onTimeCompleted: (!widget.reservationData.containsKey('startTime') ||
                widget.reservationData['startTime'] == null ||
                widget.reservationData['startTime'].toString().isEmpty)
                ? () => _showPersonPicker()
                : null,
          ),

          PersonCountWidget(
            reservationData: widget.reservationData,
            onUpdateUI: () => widget.onUpdateUI(),
            // 값이 비어있을 때만 자동으로 다음 단계로
            onPersonSelected: (!widget.reservationData.containsKey('personCount') ||
                widget.reservationData['personCount'] == null ||
                widget.reservationData['personCount'] <= 0)
                ? () => _showLocationPicker()
                : null,
          ),

          MeetingPlaceInfoWidget(
            reservationData: widget.reservationData,
            needLocationInput: widget.needLocationInput,
            infoService: ReservationInfoService(),
            onUpdateLocation: (meetingPlace) {
              widget.onUpdateUI();
            },
            isEditable: true,
            userId: widget.userId,
            requestId: widget.requestId,
            // 값이 비어있을 때만 자동으로 다음 단계로
            onLocationSelected: widget.reservationService.isMeetingPlaceEmpty(widget.reservationData)
                ? () => _showPurposePicker()
                : null,
          ),

          PurposeWidget(
            reservationData: widget.reservationData,
            onUpdateUI: () => widget.onUpdateUI(),
            // 값이 비어있을 때는 자동으로 닫히지 않고, 선택되어 있을 때만 수정 후 닫힘
            onPurposeSelected: widget.reservationService.isPurposeEmpty(widget.reservationData)
                ? null
                : () => widget.onUpdateUI(),
          ),
        ],
      ),
    );
  }
}