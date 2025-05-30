// lib/tripfriends/friendslist/models/location_model.dart
class LocationModel {
  final String? city;
  final String? nationality;

  LocationModel({
    this.city,
    this.nationality,
  });

  factory LocationModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return LocationModel();

    return LocationModel(
      city: map['city'],
      nationality: map['nationality'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'nationality': nationality,
    };
  }

  bool isValid() {
    return city != null && nationality != null && city!.isNotEmpty && nationality!.isNotEmpty;
  }
}