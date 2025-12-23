import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_price_model.dart';
import '../constants/api_constants.dart';


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
}
