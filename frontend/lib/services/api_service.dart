import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {


  static Future<String?> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String emailCode,
    required String sponsorCode,
    required String gender,
    required Map<String, dynamic> country,
    required Map<String, dynamic> language,
    required String dob,
  }) async {
    try {
      final body = {
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "password": password,
        "confirmPassword": confirmPassword,
        "emailCode": emailCode,
        "sponsorCode": sponsorCode,
        "gender": gender,
        "country": country,
        "language": language,
        "dob": dob.trim(),
      };

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Make sure backend sends {"eid": "123456789"}
        return data['eid'];
      } else {
        print("Failed to create user: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error creating user: $e");
      return null;
    }
  }
}
