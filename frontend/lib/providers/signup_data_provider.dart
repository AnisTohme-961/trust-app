import 'package:flutter/material.dart';
import '../models/language_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider extends ChangeNotifier {
  String selectedLanguage = '';
  String selectedLanguageId = '';
  String firstName;
  String lastName;
  String sponsorCode;
  String gender;
  String country = '';
  String countryId = '';
  String dob = '';
  String email = '';
  String emailCode = '';
  String password = '';
  String confirmPassword = '';

  int emailCodeSecondsLeft = 0;
  bool emailCodeVerified = false;

  bool isReturningUser = false;
  bool isRegistered = false;
  bool justRegistered = false;

  String eid = '';

  // NEW VARIABLES FOR COOLDOWN
  String emailCooldownEnd = ""; // stored ISO 8601 timestamp
  bool isCooldownActive = false;

  UserProvider({
    this.selectedLanguage = "",
    this.selectedLanguageId = "",
    this.firstName = "",
    this.lastName = "",
    this.sponsorCode = "",
    this.gender = "",
    this.country = "",
    this.countryId = "",
    this.dob = "",
    this.email = "",
    this.emailCode = "",
    this.password = "",
    this.confirmPassword = "",
    this.eid = "",
  });

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

  /// Save the cooldown end time in secure storage
  Future<void> setEmailCooldownEnd(DateTime endTime, FlutterSecureStorage storage) async {
    emailCooldownEnd = endTime.toIso8601String();
    await storage.write(key: 'emailCooldownEnd', value: emailCooldownEnd);
    notifyListeners();
  }

  /// Restore cooldown when app opens or provider loads
  Future<void> restoreEmailCooldown(FlutterSecureStorage storage) async {
    final saved = await storage.read(key: 'emailCooldownEnd');

    if (saved == null) {
      emailCodeSecondsLeft = 0;
      isCooldownActive = false;
      notifyListeners();
      return;
    }

    emailCooldownEnd = saved;

    final end = DateTime.parse(saved);
    final now = DateTime.now();

    int remaining = end.difference(now).inSeconds;

    if (remaining > 0) {
      emailCodeSecondsLeft = remaining;
      isCooldownActive = true;
      notifyListeners();
    } else {
      emailCodeSecondsLeft = 0;
      isCooldownActive = false;
      notifyListeners();
    }
  }

  // --------------------------
  // PERSISTENCE
  // --------------------------

  Future<void> loadFromStorage(FlutterSecureStorage storage) async {
    String? storedEID = await storage.read(key: 'eid');

    if (storedEID != null) {
      eid = storedEID;
      firstName = await storage.read(key: 'firstName') ?? '';
      lastName = await storage.read(key: 'lastName') ?? '';
      isRegistered = true;
      justRegistered = false;

      // RESTORE COOLDOWN
      emailCooldownEnd = await storage.read(key: 'emailCooldownEnd') ?? "";
      await restoreEmailCooldown(storage);

      notifyListeners();
    }
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