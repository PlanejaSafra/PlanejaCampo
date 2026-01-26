import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of job post
enum JobType {
  offeringWork, // Produtor offering a job (preciso de sangrador)
  seekingWork, // Sangrador looking for work (estou disponível)
}

class JobPost {
  final String id;
  final String userId;
  final String userName;
  final JobType type;
  final List<String> regions; // Regions where the job/availability is
  final String description;
  final String contactPhone;
  final double? offeredPercentage; // % offered to tapper (for offeringWork)
  final int? treesCount; // Number of trees (for offeringWork)
  final String? municipality; // Municipality
  final DateTime createdAt;
  final DateTime validUntil;

  JobPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.regions,
    required this.description,
    required this.contactPhone,
    this.offeredPercentage,
    this.treesCount,
    this.municipality,
    required this.createdAt,
    required this.validUntil,
  });

  /// Check if post is expiring soon (within 3 days)
  bool get isExpiringSoon {
    final daysUntilExpiry = validUntil.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  /// Check if post has expired
  bool get isExpired => validUntil.isBefore(DateTime.now());

  /// Days remaining until expiration
  int get daysRemaining {
    final days = validUntil.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  factory JobPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    JobType type = JobType.seekingWork;
    if (data['type'] == 'offeringWork') {
      type = JobType.offeringWork;
    }

    return JobPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: type,
      regions: List<String>.from(data['regions'] ?? []),
      description: data['description'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      offeredPercentage: data['offeredPercentage']?.toDouble(),
      treesCount: data['treesCount']?.toInt(),
      municipality: data['municipality'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type == JobType.offeringWork ? 'offeringWork' : 'seekingWork',
      'regions': regions,
      'description': description,
      'contactPhone': contactPhone,
      'offeredPercentage': offeredPercentage,
      'treesCount': treesCount,
      'municipality': municipality,
      'createdAt': Timestamp.fromDate(createdAt),
      'validUntil': Timestamp.fromDate(validUntil),
    };
  }
}
