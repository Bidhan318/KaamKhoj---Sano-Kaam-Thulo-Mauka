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
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool workerCompleted;
  final bool clientCompleted;
  final bool isDirectHire;

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
    this.startedAt,
    this.completedAt,
    this.workerCompleted = false,
    this.clientCompleted = false,
    this.isDirectHire = false,
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
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      workerCompleted: map['workerCompleted'] ?? false,
      clientCompleted: map['clientCompleted'] ?? false,
      isDirectHire: map['isDirectHire'] ?? false,
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
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'workerCompleted': workerCompleted,
      'clientCompleted': clientCompleted,
      'isDirectHire': isDirectHire,
    };
  }

  JobModel copyWith({
    String? status,
    String? assignedWorkerUid,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? workerCompleted,
    bool? clientCompleted,
    bool? isDirectHire,
  }) {
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
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      workerCompleted: workerCompleted ?? this.workerCompleted,
      clientCompleted: clientCompleted ?? this.clientCompleted,
      isDirectHire: isDirectHire ?? this.isDirectHire,
    );
  }
}