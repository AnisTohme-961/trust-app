import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class AuthService {
  // Secure storage instance
  static final _storage = FlutterSecureStorage();

  // Key for storing the token
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'user_email'; // new
  static const _eidKey = 'user_eid'; // new

  // Send code for sign-in (by EID or email)
  static Future<void> sendCode({required String identifier}) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/send-code-sign-in"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );

    print('Send code response: ${response.statusCode} ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to send code: ${response.body}');
    }
  }

  // Verify code (optional - for UI feedback only)
  static Future<bool> verifyCode({
    required String identifier,
    required String code,
  }) async {
    print('Verifying code: identifier=$identifier, code=$code');

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/verify-code-sign-in"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'code': code}),
    );

    print('Verify code response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['valid'] == true;
    } else if (response.statusCode == 400) {
      return false;
    } else {
      throw Exception('Failed to verify code: ${response.body}');
    }
  }

  // Sign in
  static Future<bool> signIn({
    required String identifier,
    required String password,
    required String code,
    required bool rememberMe,
  }) async {
    final body = {
      'identifier': identifier,
      'password': password,
      'code': code,
      'rememberMe': rememberMe,
    };

    print('=== SIGN IN REQUEST ===');
    print('URL: ${ApiConstants.baseUrl}/sign-in');
    print('Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/sign-in"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('=== SIGN IN RESPONSE ===');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    print('Headers: ${response.headers}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save token securely
      final token = data['token']; // Make sure your API returns a 'token'
      final email = data['email']; // new
      final eid = data['eid']; // new
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
        print('Token stored securely');
      }

      if (email != null) {
        // new
        await _storage.write(key: _emailKey, value: email);
        print('Email stored securely');
      }

      if (eid != null) {
        // new
        await _storage.write(key: _eidKey, value: eid);
        print('EID stored securely');
      }

      return true;
    } else if (response.statusCode == 423) {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        payload = {'remainingSeconds': 86400, 'error': 'Account locked'};
      }
      throw Exception(jsonEncode(payload));
    } else if (response.statusCode == 401) {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        payload = {'error': 'Invalid credentials'};
      }
      throw Exception(jsonEncode(payload));
    } else {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        payload = {'error': response.body};
      }
      payload['status'] = response.statusCode;
      throw Exception(jsonEncode(payload));
    }
  }

  // Retrieve token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getEmail() async {
    // new
    return await _storage.read(key: _emailKey);
  }

  // ✅ Retrieve EID
  static Future<String?> getEID() async {
    // new
    return await _storage.read(key: _eidKey);
  }

  // Delete token (logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    print('Token deleted from secure storage');
  }

  static Future<void> registerPin(String pin) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception("User not authenticated");
    }

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/register-pin"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'pin': pin}),
    );

    if (response.statusCode == 200) {
      print('PIN registered successfully');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: invalid or expired token');
    } else {
      throw Exception('Failed to register PIN: ${response.body}');
    }
  }

  //   static Future<bool> validatePin(String pin) async {
  //   final token = await _storage.read(key: _tokenKey);
  //   if (token == null) throw Exception("User not authenticated");

  //   final response = await http.post(
  //     Uri.parse("${ApiConstants.baseUrl}/validate-pin"),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //     body: jsonEncode({'pin': pin}),
  //   );

  //   if (response.statusCode == 200) {
  //     return true;
  //   } else if (response.statusCode == 401) {
  //     return false;
  //   } else {
  //     throw Exception('Failed to validate PIN: ${response.body}');
  //   }
  // }

  static Future<void> registerPattern(List<int> pattern) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw Exception("User not authenticated");
    }

    if (pattern.length < 4) {
      throw Exception("Pattern must have at least 4 dots");
    }

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/register-pattern"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'pattern': pattern}),
    );

    if (response.statusCode == 200) {
      print('Pattern registered successfully');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: invalid or expired token');
    } else {
      throw Exception('Failed to register pattern: ${response.body}');
    }
  }

  static Future<void> sendResetCode(String identifier) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/send-reset-code"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  static Future<bool> verifyResetCode({
    required String identifier,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['verified'] == true;
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception(error);
    }
  }

  static Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
    required String confirmPassword,
    required String method,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/reset-password"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'code': code,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'method': method,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['error'] ?? 'Failed to reset password',
      );
    }
  }

  static Future<Map<String, String>> generateTOTP(String email) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/generate-totp"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'secret': data['secret'], 'qrUrl': data['qrUrl']};
    } else {
      final error =
          jsonDecode(response.body)['error'] ?? 'Failed to generate TOTP';
      throw Exception(error);
    }
  }

  static Future<bool> verifyTOTP({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/verify-totp"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['verified'] == true;
    } else if (response.statusCode == 401) {
      return false;
    } else {
      final error =
          jsonDecode(response.body)['error'] ?? 'Failed to verify code';
      throw Exception(error);
    }
  }

  static Future<String> sendEidCode(String email) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/send-eid-code"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['code']; // return server-generated code
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to send code';
      throw Exception(error);
    }
  }

  // verify EID code
  static Future<bool> verifyEidCode({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/verify-eid-code"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['valid'] == true;
    } else if (response.statusCode == 401) {
      return false; // invalid or expired
    } else {
      final error =
          jsonDecode(response.body)['error'] ?? 'Failed to verify code';
      throw Exception(error);
    }
  }

  static Future<bool> sendEidEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/forgot-eid"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Check if EID still exists on server
static Future<bool> checkEidExists(String eid) async {
  final response = await http.post(
    Uri.parse("${ApiConstants.baseUrl}/check-eid"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"eid": eid}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["available"] == false; // if available=false → EID exists
  }

  // If server returns error → treat as not existing
  return false;
}


}
