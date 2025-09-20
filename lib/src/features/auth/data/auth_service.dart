import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class AuthService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<String> login(String email, String password) async {
    _logger.i('Attempting login API call to $baseUrl/auth/login');
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        final accessToken = response.data['data']['accessToken'] as String;
        _logger.i('accessToken: $accessToken');

        return accessToken;
      } else {
        throw Exception('Failed to login with status ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error during API call: $e');
      rethrow;
    }
  }
}
