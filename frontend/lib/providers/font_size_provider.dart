import 'package:flutter/foundation.dart';

class FontSizeProvider extends ChangeNotifier {
  String _selectedSize = 'Medium';

  String get selectedSize => _selectedSize;

  // Get the font size multiplier based on selection
  double get fontSizeValue {
    switch (_selectedSize) {
      case 'Large':
        return 20.0;
      case 'Medium':
      default:
        return 15.0;
    }
  }

  // Method to update font size
  void setFontSize(String size) {
    _selectedSize = size;
    notifyListeners();
  }

  // Helper method to get scaled font size
  double getScaledSize(double baseSize) {
    // If base size is 15 (medium), scale it proportionally
    if (baseSize == 15.0) {
      return fontSizeValue;
    }
    // For other sizes, scale proportionally
    double ratio = fontSizeValue / 15.0;
    return baseSize * ratio;
  }
}
