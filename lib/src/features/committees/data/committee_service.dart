import 'package:commipay_app/utils/token_storage.dart';
import 'package:dio/dio.dart';
import 'committee_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class CommitteeService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, Object>> fetchCommittees({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final token = await TokenStorage.getToken();
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null) 'search': search,
    };

    try {
      final response = await _dio.get(
        '$baseUrl/committee',
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> committeesJson = data['data'] as List<dynamic>;
        final int total = data['total'] is int
            ? data['total']
            : int.tryParse(data['total'].toString()) ?? 0;

        final committees = committeesJson
            .map((json) => Committee.fromJson(json))
            .toList();
        return {'committees': committees, 'total': total};
      } else {
        throw Exception('Failed to load committees');
      }
    } catch (e) {
      _logger.e('Error during API call: $e');
      rethrow;
    }
  }

  Future<bool> addCommittee(Map<String, dynamic> committeeData) async {
    final token = await TokenStorage.getToken();

    try {
      final response = await _dio.post(
        '$baseUrl/committee',
        data: committeeData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _logger.w('Add committee failed: ${response.data}');
        return false;
      }
    } catch (e) {
      _logger.e('Error adding committee: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchCommitteeById(String id) async {
    final token = await TokenStorage.getToken();
    try {
      final response = await _dio.get(
        '$baseUrl/committee/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch committee details');
      }
    } catch (e) {
      _logger.e('Error during API call: $e');
      rethrow;
    }
  }
}
