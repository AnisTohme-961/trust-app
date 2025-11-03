import 'package:flutter/material.dart';
import '../models/language_model.dart';
import '../services/language_api_service.dart';

class LanguageProvider extends ChangeNotifier {
  final _apiService = LanguageApiService();
  List<LanguageModel> _languages = [];
  List<LanguageModel> get languages => _languages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future <void> loadLanguages() async {
    _isLoading = true;
    notifyListeners();

    try {
    _languages = await _apiService.fetchLanguages(); 
    }
    catch (e) {
      debugPrint('Error fetching languages: $e');
    }
    finally {
      _isLoading = false;
      notifyListeners();
    }

  }
}
