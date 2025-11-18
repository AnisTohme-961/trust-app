import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl =>
      kIsWeb ? "http://127.0.0.1:8080" : "http://10.0.3.130:8080";
}
