// lib/models/job_model.dart
//
// PURPOSE: Represents a job request posted by a client.
// Stored in Firestore under /jobs/{jobId}.
// Workers nearby receive these and can accept/decline.

class JobModel {
  final String jobId;
  final String clientUid;       // Who posted this job
  final String clientName;
  final String title;           // e.g. "Fix leaking pipe"
  final String description;
  final String requiredSkill;   // e.g. "Plumber"
  final double budget;          // Client's budget in NPR
  final double latitude;        // Job location
  final double longitude;
  final String address;
  final String status;          // 'open' | 'assigned' | 'completed' | 'cancelled'
  final String? assignedWorkerUid; // Set when a worker accepts
  final DateTime postedAt;

  JobModel({
    required this.jobId,
    required this.clientUid,
    required this.clientName,
    required this.title,
    required this.description,
    required this.requiredSkill,
    required this.budget,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.status = 'open',
    this.assignedWorkerUid,
    required this.postedAt,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      jobId: id,
      clientUid: map['clientUid'] ?? '',
      clientName: map['clientName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requiredSkill: map['requiredSkill'] ?? '',
      budget: (map['budget'] ?? 0).toDouble(),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      status: map['status'] ?? 'open',
      assignedWorkerUid: map['assignedWorkerUid'],
      postedAt: DateTime.parse(map['postedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientUid': clientUid,
      'clientName': clientName,
      'title': title,
      'description': description,
      'requiredSkill': requiredSkill,
      'budget': budget,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'assignedWorkerUid': assignedWorkerUid,
      'postedAt': postedAt.toIso8601String(),
    };
  }

  JobModel copyWith({String? status, String? assignedWorkerUid}) {
    return JobModel(
      jobId: jobId,
      clientUid: clientUid,
      clientName: clientName,
      title: title,
      description: description,
      requiredSkill: requiredSkill,
      budget: budget,
      latitude: latitude,
      longitude: longitude,
      address: address,
      status: status ?? this.status,
      assignedWorkerUid: assignedWorkerUid ?? this.assignedWorkerUid,
      postedAt: postedAt,
    );
  }
}