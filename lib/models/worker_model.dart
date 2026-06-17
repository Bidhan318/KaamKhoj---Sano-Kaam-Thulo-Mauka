// lib/models/worker_model.dart
//
// PURPOSE: Represents a worker's public profile on the map and in listings.
// Stored in Firestore under /workers/{uid}.
// This is separate from UserModel because workers have extra fields
// (skills, rate, location, availability) that clients don't need.

class WorkerModel {
  final String uid;             // Same UID as their UserModel
  final String name;
  final String phone;
  final String? profileImage;   // Firebase Storage URL
  final List<String> skills;    // e.g. ['Electrician', 'Plumber']
  final double ratePerDay;      // In NPR
  final double rating;          // 0.0 – 5.0, updated after each job
  final int totalReviews;
  final bool isAvailable;       // Worker can toggle this on/off
  final double latitude;        // Current GPS latitude (updated live)
  final double longitude;       // Current GPS longitude (updated live)
  final String address;         // Human-readable address from geocoding
  double? distanceFromClient;   // Calculated locally – NOT stored in Firestore

  WorkerModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.profileImage,
    required this.skills,
    required this.ratePerDay,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isAvailable = true,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.distanceFromClient,
  });

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'],
      skills: List<String>.from(map['skills'] ?? []),
      ratePerDay: (map['ratePerDay'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'skills': skills,
      'ratePerDay': ratePerDay,
      'rating': rating,
      'totalReviews': totalReviews,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
  WorkerModel copyWith({
    String? name,
    String? phone,
    String? profileImage,
    List<String>? skills,
    double? ratePerDay,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    String? address,
    double? distanceFromClient,
    double? rating,
    int? totalReviews,
    bool clearProfileImage = false,
  }) {
    return WorkerModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage:
      clearProfileImage ? null : (profileImage ?? this.profileImage),
      skills: skills ?? this.skills,
      ratePerDay: ratePerDay ?? this.ratePerDay,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      distanceFromClient:
      distanceFromClient ?? this.distanceFromClient,
    );
  }

}