import 'package:material_ui/material_ui.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  final List<TaskModel> _tasks = [];
  final bool _isLoading = false;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  void addTask(TaskModel task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTaskStatus(String taskId, String newStatus) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final old = _tasks[index];
      _tasks[index] = TaskModel(
        id: old.id,
        title: old.title,
        location: old.location,
        status: newStatus,
        priority: old.priority,
        assignedWorkerUid: old.assignedWorkerUid,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }
}
