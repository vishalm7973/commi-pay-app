import 'package:commipay_app/utils/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:commipay_app/main.dart'; // where navigatorKey is defined

class ApiClient {
  static final Dio dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            await TokenStorage.deleteToken();
            // Navigate to login
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
          return handler.next(e);
        },
      ),
    );
}
