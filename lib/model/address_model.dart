class AddressModel {
  final String id;
  final String type; // 'Home', 'Office', 'Other'
  final String mapAddress;
  final String? flatNo;
  final String? landmark;
  final double latitude;
  final double longitude;

  AddressModel({
    required this.id,
    required this.type,
    required this.mapAddress,
    this.flatNo,
    this.landmark,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'mapAddress': mapAddress,
      'flatNo': flatNo,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      type: map['type'] ?? 'Other',
      mapAddress: map['mapAddress'] ?? '',
      flatNo: map['flatNo'],
      landmark: map['landmark'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (flatNo != null && flatNo!.isNotEmpty) parts.add(flatNo!);
    if (landmark != null && landmark!.isNotEmpty) parts.add(landmark!);
    parts.add(mapAddress);
    return parts.join(', ');
  }
}
