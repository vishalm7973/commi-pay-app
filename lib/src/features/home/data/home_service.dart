import 'package:commipay_app/src/features/home/data/analytics_stats_model.dart';
import 'package:commipay_app/src/features/home/data/pending_member_model.dart';
import 'package:commipay_app/src/features/home/data/pending_payment_records_model.dart';
import 'package:commipay_app/utils/app_client.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:commipay_app/utils/token_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeService {
  final Dio _dio = ApiClient.dio;
  final Logger _logger = Logger();
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<AnalyticsStats> fetchStats() async {
    final token = await TokenStorage.getToken();
    try {
      final response = await _dio.get(
        '$baseUrl/analytics/stats',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AnalyticsStats.fromJson(data);
      } else {
        _logger.w(
          'Analytics fetch failed: ${response.statusCode} ${response.data}',
        );
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      _logger.e('Error fetching home stats: $e');
      rethrow;
    }
  }

  Future<PendingMembersPageResponse> fetchPendingMembers({
    int page = 1,
    int limit = 10,
  }) async {
    final token = await TokenStorage.getToken();
    try {
      final response = await _dio.get(
        '$baseUrl/analytics/pending-members',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return PendingMembersPageResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.w(
          'Pending members fetch failed: ${response.statusCode} ${response.data}',
        );
        throw Exception('Failed to load pending members');
      }
    } catch (e) {
      _logger.e('Error fetching pending members: $e');
      rethrow;
    }
  }

  Future<PendingPaymentRecordsResponse> fetchMemberPaymentRecords(
    String memberId,
  ) async {
    final token = await TokenStorage.getToken();
    try {
      final response = await _dio.get(
        '$baseUrl/analytics/payments-records/$memberId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return PendingPaymentRecordsResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.w(
          'Fetch member payment records failed: ${response.statusCode} ${response.data}',
        );
        throw Exception('Failed to load payment records');
      }
    } catch (e) {
      _logger.e('Error fetching payment records for $memberId: $e');
      rethrow;
    }
  }
}
