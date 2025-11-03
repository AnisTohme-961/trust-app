import 'package:flutter/material.dart';

class SignUpDataModel extends ChangeNotifier {
  // Store all form data
  String _firstName = '';
  String _lastName = '';
  String _sponsor = '';
  String _gender = '';

  // Getters
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get sponsor => _sponsor;
  String get gender => _gender;

  // Setters with notifyListeners
  void setFirstName(String value) {
    _firstName = value;
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value;
    notifyListeners();
  }

  void setSponsor(String value) {
    _sponsor = value;
    notifyListeners();
  }

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  // Optional: Clear all data
  void clearData() {
    _firstName = '';
    _lastName = '';
    _sponsor = '';
    _gender = '';
    notifyListeners();
  }
}