import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_price_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class CurrencyService {
  Future<List<CurrencyPrice>> getCurrencies() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/currencies");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((e) => CurrencyPrice.fromJson(e)).toList();
    }

    throw Exception("Failed to load currencies");
  }

 Future<void> updateUserCurrency(String currencyCode) async {
  final token = await AuthService.getToken();

  final response = await http.put(
    Uri.parse('${ApiConstants.baseUrl}/users/currency'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"currencyCode": currencyCode}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update currency');
  }
}
}
