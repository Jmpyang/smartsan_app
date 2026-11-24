class TaskModel {
  final String id;
  final String title;
  final String location;
  final String status;
  final String priority;
  final String assignedWorkerUid;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.priority,
    required this.assignedWorkerUid,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'status': status,
      'priority': priority,
      'assignedWorkerUid': assignedWorkerUid,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      assignedWorkerUid: json['assignedWorkerUid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
