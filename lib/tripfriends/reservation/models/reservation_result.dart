// 결제 및 예약 생성 결과를 저장하기 위한 모델 클래스
class ReservationResult {
  final String reservationId;
  final String paymentId;

  ReservationResult(this.reservationId, this.paymentId);
}