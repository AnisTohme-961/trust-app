class CurrencyPrice {
  final String symbol;
  final double price;

  CurrencyPrice({required this.symbol, required this.price});

  factory CurrencyPrice.fromJson(Map<String, dynamic> json) {
    return CurrencyPrice(
      symbol: json['symbol'],
      price: double.parse(json['price']),
    );
  }
}
