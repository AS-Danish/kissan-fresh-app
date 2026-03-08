class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? address;
  final String? imageUrl;
  final String role;
  final bool onboardingCompleted;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.address,
    this.imageUrl,
    required this.role,
    required this.onboardingCompleted,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'imageUrl': imageUrl,
      'role': role,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      address: map['address'],
      imageUrl: map['imageUrl'],
      role: map['role'] ?? 'user',
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
