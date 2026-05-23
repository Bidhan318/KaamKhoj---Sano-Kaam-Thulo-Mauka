// lib/models/user_model.dart
//
// PURPOSE: Represents a registered user (either Client or Worker role).
// Stored in Firestore under /users/{uid}.
// The 'role' field determines which UI flows the user sees after login.

class UserModel {
  final String uid;           // Firebase Auth UID – unique identifier
  final String name;          // Display name
  final String phone;         // Phone number used for OTP login
  final String email;         // Optional email
  final String role;          // 'client' or 'worker'
  final String? profileImage; // URL from Firebase Storage (nullable)
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.email = '',
    this.profileImage,
    required this.createdAt,
  });

  // Converts Firestore document snapshot → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {  //converts raw Firestore data (a Map) into a proper Dart object
    return UserModel(
      uid: map['uid'] ?? '',  //?? means "if this field is missing, use this default value"
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'client',
      profileImage: map['profileImage'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Converts UserModel → Map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Creates a copy with some fields changed (useful in providers)
  UserModel copyWith({
    String? name,
    String? email,
    String? profileImage,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }
}