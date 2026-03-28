class RiderModel {
  final String riderId;
  final String name;
  final String phone;
  final String avatarUrl;

  RiderModel({
    required this.riderId,
    required this.name,
    required this.phone,
    required this.avatarUrl,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      riderId: json['riderId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
    };
  }
}
