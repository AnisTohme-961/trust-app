import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_price_model.dart';

class BinanceService {

  Future<CurrencyPrice?> getPrice(String symbol) async {
    try {
      final url = Uri.parse("https://api.binance.com/api/v3/ticker/price?symbol=$symbol");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CurrencyPrice.fromJson(data);
      } else {
        print("Error: ${response.statusCode}");
        return null;
      }

    } catch (e) {
      print("Error fetching price: $e");
      return null;
    }
  }
}
