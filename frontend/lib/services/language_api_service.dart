import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/language_model.dart';
import '../constants/api_constants.dart';

class LanguageApiService {
  final String baseUrl;

  LanguageApiService({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Future<List<LanguageModel>> fetchLanguages() async {
    final response = await http.get(Uri.parse('$baseUrl/languages'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => LanguageModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch ');
    }
  }
}
