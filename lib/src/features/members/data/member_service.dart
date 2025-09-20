import 'package:commipay_app/src/features/members/data/member_model.dart';
import 'package:commipay_app/utils/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class MemberService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, Object>> fetchMembers({
    int page = 1,
    int limit = 20,
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
        '$baseUrl/users',
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> membersJson = data['data'] as List<dynamic>;
        final int total = data['total'] is int
            ? data['total']
            : int.tryParse(data['total'].toString()) ?? 0;

        final members = membersJson
            .map((json) => Member.fromJson(json))
            .toList();
        return {'members': members, 'total': total};
      } else {
        throw Exception('Failed to load members');
      }
    } catch (e) {
      _logger.e('Error during API call: $e');
      rethrow;
    }
  }

  Future<bool> addMember({
    required String firstName,
    String? lastName,
    required String countryCode,
    required String phoneNumber,
  }) async {
    final token = await TokenStorage.getToken();
    final data = {
      'firstName': firstName,
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
    };

    if (lastName != null && lastName.isNotEmpty) {
      data['lastName'] = lastName;
    }

    try {
      final response = await _dio.post(
        '$baseUrl/users',
        data: data,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _logger.e(
          'Failed to add member: ${response.statusCode} - ${response.data}',
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error during add member API call: $e');
      return false;
    }
  }
}
