import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterUid;
  final String description;
  final String category;
  final String priority;
  final String imageUrl;
  final String locationString;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String status;

  ReportModel({
    required this.id,
    required this.reporterUid,
    required this.description,
    required this.category,
    required this.priority,
    required this.imageUrl,
    required this.locationString,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.status = 'Reported',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterUid': reporterUid,
      'description': description,
      'category': category,
      'priority': priority,
      'imageUrl': imageUrl,
      'locationString': locationString,
      'lat': lat,
      'lng': lng,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }

  factory ReportModel.fromJson(String id, Map<String, dynamic> json) {
    return ReportModel(
      id: id,
      reporterUid: json['reporterUid'] ?? 'anonymous',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      priority: json['priority'] ?? 'Low',
      imageUrl: json['imageUrl'] ?? '',
      locationString: json['locationString'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: json['status'] ?? 'Reported',
    );
  }
}
