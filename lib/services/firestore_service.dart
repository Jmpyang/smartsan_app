import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

// 🎯 Model for a simple Issue Report
class IssueReport {
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String status;
  final String reportedBy;
  
  IssueReport({
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.status = 'Pending', // Default status
    required this.reportedBy,
  });

  // Method to convert the Dart object to a JSON-compatible Map for Firebase
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'reportedBy': reportedBy,
      'timestamp': ServerValue.timestamp, // Firebase utility to record server time
    };
  }
}

class FirebaseService {
  // Get a reference to the root of the Realtime Database
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // --- 1. WRITE FUNCTION (Reporting an Issue) ---
  Future<void> reportIssue(IssueReport report) async {
    // 1. Define the path where the data will be stored (e.g., 'issues/unique_id')
    final issuesRef = _databaseRef.child('issues').push();
    
    try {
      // 2. Set the data using the toJson map
      await issuesRef.set(report.toJson());
      if (kDebugMode) {
        print('Issue successfully reported with key: ${issuesRef.key}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting issue: $e');
      }
      rethrow; // Re-throw the error for the UI to handle
    }
  }

  // --- 2. READ FUNCTION (Real-time stream for Dashboard) ---
  // This function returns a stream of DataSnapshot, allowing you to react 
  // immediately when data changes in the 'issues' path.
  Stream<DatabaseEvent> getIssuesStream() {
    return _databaseRef.child('issues').onValue;
  }
}