import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:commipay_app/utils/token_storage.dart';

class ProfileService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final String? token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Auth token not found');
    }

    try {
      final response = await _dio.get(
        '$baseUrl/current-user',
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('response.data: ${response.data}');
        return response.data;
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      _logger.e('Error during API call: $e');
      rethrow;
    }
  }
}
