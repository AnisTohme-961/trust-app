import 'dart:convert';

import 'package:http/http.dart' as http;


class CountryService {
  final String baseUrl;

  CountryService({required this.baseUrl});

  Future<List<Map<String, String>>> fetchCountries() async {
    final response = await http.get(Uri.parse('$baseUrl/countries'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<Map<String, String>>((item) => {
        'id': item['ID'],
        'name': item['Name'],
        'flag': item['Flag'],
      }).toList();
    } else {
      throw Exception('Failed to load countries');
    }
  }
}