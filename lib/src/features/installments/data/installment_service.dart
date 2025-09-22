import 'package:commipay_app/src/features/installments/data/installment_model.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:commipay_app/utils/token_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InstallmentService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<Map<String, dynamic>> fetchInstallments({
    required String committeeId,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await TokenStorage.getToken();
    try {
      final response = await _dio.get(
        '$baseUrl/installment/$committeeId',
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> installmentsJson = data['data'] as List<dynamic>;
        final int total = data['total'] is int
            ? data['total']
            : int.tryParse(data['total'].toString()) ?? 0;

        final installments = installmentsJson
            .map((json) => Installment.fromJson(json))
            .toList();
        return {'installments': installments, 'total': total};
      } else {
        throw Exception('Failed to load installments');
      }
    } catch (e) {
      _logger.e('Error fetching installments: $e');
      rethrow;
    }
  }

  Future<bool> addInstallment(Map<String, dynamic> installmentData) async {
    final token = await TokenStorage.getToken();
    try {
      final response = await _dio.post(
        '$baseUrl/installment',
        data: installmentData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _logger.w('Add installment failed: ${response.data}');
        return false;
      }
    } catch (e) {
      _logger.e('Error adding installment: $e');
      return false;
    }
  }
}
