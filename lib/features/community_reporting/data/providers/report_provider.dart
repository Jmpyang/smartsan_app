import 'package:material_ui/material_ui.dart';
import '../../../../services/firestore_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  Future<void> submitReport({
    required String description,
    required String category,
    required String priority,
    required String imageUrl,
    required String locationString,
    required double lat,
    required double lng,
    required String reporterUid,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _reportService.submitReport(
        description: description,
        category: category,
        priority: priority,
        imageUrl: imageUrl,
        locationString: locationString,
        lat: lat,
        lng: lng,
        reporterUid: reporterUid,
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
