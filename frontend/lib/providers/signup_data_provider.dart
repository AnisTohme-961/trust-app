import 'package:flutter/material.dart';
import '../models/language_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider extends ChangeNotifier {
  String selectedLanguage = '';
  String selectedLanguageId = '';
  String firstName = '';
  String lastName = '';
  String sponsorCode = '';
  String gender = '';
  String country = '';
  String countryId = '';
  String dob = '';
  String email = '';
  String emailCode = '';
  String password = '';
  String confirmPassword = '';

  // Cooldown & verification
  int emailCodeSecondsLeft = 0;
  bool emailCodeVerified = false;
  bool isCooldownActive = false;

  bool isCodeCorrect = false;
  bool isCodeValid = false;

  // Registration info
  bool isReturningUser = false;
  bool isRegistered = false;
  bool justRegistered = false;
  String eid = '';

  UserProvider();

  // --------------------------
  // BASIC SETTERS
  // --------------------------
  void setLanguage(LanguageModel lang) {
    selectedLanguage = lang.name;
    selectedLanguageId = lang.id;
    notifyListeners();
  }

  void setFirstName(String val) {
    firstName = val;
    notifyListeners();
  }

  void setLastName(String val) {
    lastName = val;
    notifyListeners();
  }

  void setSponsorCode(String val) {
    sponsorCode = val;
    notifyListeners();
  }

  void setGender(String val) {
    gender = val;
    notifyListeners();
  }

  void setCountry(String name, String id) {
    country = name;
    countryId = id;
    notifyListeners();
  }

  void setDob(String val) {
    dob = val;
    notifyListeners();
  }

  void setEmail(String val) {
    email = val;
    notifyListeners();
  }

  void setEmailCode(String val) {
    emailCode = val;
    notifyListeners();
  }

  void setEmailCodeTimer(int seconds) {
    emailCodeSecondsLeft = seconds;
    notifyListeners();
  }

  void setEmailCodeVerified(bool val) {
    emailCodeVerified = val;
    notifyListeners();
  }

   void setCodeCorrect(bool val) {
    isCodeCorrect = val;
    notifyListeners();
  }

  void setCodeValid(bool val) {
    isCodeValid = val;
    notifyListeners();
  }

  void setPassword(String val) {
    password = val;
    notifyListeners();
  }

  void setConfirmPassword(String val) {
    confirmPassword = val;
    notifyListeners();
  }

  void setEID(String val) {
    eid = val;
    notifyListeners();
  }

  void markAsRegistered() {
    isRegistered = true;
    notifyListeners();
  }

  // --------------------------
  // COOLDOWN SYSTEM
  // --------------------------
  Future<void> setEmailCooldownEndForEmail(
    String email,
    DateTime endTime,
    FlutterSecureStorage storage,
  ) async {
    final key = "cooldown_$email";
    await storage.write(key: key, value: endTime.toIso8601String());
    emailCodeSecondsLeft = endTime.difference(DateTime.now()).inSeconds;
    isCooldownActive = emailCodeSecondsLeft > 0;
    notifyListeners();
  }

  Future<void> restoreEmailCooldownForEmail(
    String email,
    FlutterSecureStorage storage,
  ) async {
    final key = "cooldown_$email";
    final saved = await storage.read(key: key);

    if (saved == null) {
      emailCodeSecondsLeft = 0;
      isCooldownActive = false;
      notifyListeners();
      return;
    }

    final endTime = DateTime.tryParse(saved) ?? DateTime.now();
    final remaining = endTime.difference(DateTime.now()).inSeconds;

    emailCodeSecondsLeft = remaining > 0 ? remaining : 0;
    isCooldownActive = remaining > 0;

    notifyListeners();
  }

  // --------------------------
  // PERSISTENCE
  // --------------------------
  Future<void> loadFromStorage(FlutterSecureStorage storage) async {
    eid = await storage.read(key: 'eid') ?? '';
    firstName = await storage.read(key: 'firstName') ?? '';
    lastName = await storage.read(key: 'lastName') ?? '';
    isRegistered = eid.isNotEmpty;
    justRegistered = false;
    notifyListeners();
  }

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String eid,
    required FlutterSecureStorage storage,
  }) async {
    this.firstName = firstName;
    this.lastName = lastName;
    this.eid = eid;
    isRegistered = true;
    justRegistered = true;
    notifyListeners();

    await storage.write(key: 'firstName', value: firstName);
    await storage.write(key: 'lastName', value: lastName);
    await storage.write(key: 'eid', value: eid);
  }
}





  //  String selectedLanguage = '';
  // String selectedLanguageId = '';

  // String firstName = '';
  // String lastName = '';
  // String sponsorCode = '';
  // String gender = '';

  // String country = '';
  // String countryId = '';
  // String dob = '';
  // String email = '';
  // String emailCode = '';

  // String password = '';
  // String confirmPassword = '';
 

  // void setFirstName(String val) {
  //   firstName = val;
  //   notifyListeners();
  // }

  // void setLastName(String val) {
  //   lastName = val;
  //   notifyListeners();
  // }

  // void setSponsorCode(String val) {
  //   sponsorCode = val;
  //   notifyListeners();
  // }

  // void setGender(String val) {
  //   gender = val;
  //   notifyListeners();
  // }

 
  // void setCountry(String name, String id) {
  //   country = name;
  //   countryId = id;
  //   notifyListeners();
  // }

  // void setDob(String val) {
  //   dob = val;
  //   notifyListeners();
  // }

  // void setEmail(String val) {
  //   email = val;
  //   notifyListeners();
  // }

  // void setEmailCode(String val) {
  //   emailCode = val;
  //   notifyListeners();
  // }

  // void setPassword(String val) {
  //   password = val;
  //   notifyListeners();
  // }

  // void setConfirmPassword(String val) {
  //   confirmPassword = val;
  //   notifyListeners();
  // }

  // void setLanguage(String name, String id) {
  //   selectedLanguage = name;
  //   selectedLanguageId = id;
  //   notifyListeners();
  // }

  // Map<String, dynamic> toJson() {
  //   return {
  //     "firstName": firstName,
  //     "lastName": lastName,
  //     "sponsorCode": sponsorCode,
  //     "selectedGender": gender,
  //     "country": country,
  //     "dob": dob,
  //     "email": email,
  //     "emailCode": emailCode,
  //     "password": password,
  //     "confirmPassword": confirmPassword,
  //     "language": selectedLanguage,
  //   };
  // }