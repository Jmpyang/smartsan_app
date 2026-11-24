import '../core/config/constants.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = AppConstants.apiBaseUrl});

  Future<Map<String, dynamic>> getHealthStatus() async {
    return {'status': 'healthy', 'baseUrl': baseUrl};
  }
}
