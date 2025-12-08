class CurrencyPrice {
  final String code;
  final String symbol;
  final String name;
  final double price;

  CurrencyPrice({
    required this.code,
    required this.symbol,
    required this.name,
    required this.price,
  });

  factory CurrencyPrice.fromJson(Map<String, dynamic> json) {
    return CurrencyPrice(
      code: json['code'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] is String)
          ? double.tryParse(json['price']) ?? 0
          : (json['price'] as num).toDouble(),
    );
  }
}

