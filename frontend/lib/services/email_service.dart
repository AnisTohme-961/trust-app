import 'dart:convert';

import 'package:http/http.dart' as http;

class EmailService {
  final String baseUrl;
  EmailService ({ required this.baseUrl });

  Future<String?> sendCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get-code'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['code'];
    } else {
      return null;
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-code'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['valid'] ?? false;
    }
    return false;
  }

}