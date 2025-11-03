import 'package:flutter/material.dart';
import 'dart:async';


class ProtectAccessProvider extends ChangeNotifier {
  // UI state
  bool signUpGlow = false;
  bool countryDropdownOpen = false;
  bool dobDropdownOpen = false;
  bool isBtnHovered = false;
  bool isHovered = false;
  bool hideInputFields = false;
  bool showCodeSent = false;
  bool isTyping = false;
  int secondsLeft = 119;
  int attempts = 0;
  bool tooManyAttempts = false;

  // Selections / data
  String selectedCountry = '';
  String selectedCountryId = '';
  String verifiedCode = '';
  List<String> code = ["", "", "", "", "", ""];
  int selectedDay = 0;
  int selectedMonth = 0;
  int selectedYear = 0;
  bool datePicked = false;

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController countryFieldController = TextEditingController();
  final TextEditingController countrySearchController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> codeControllers =
      List.generate(6, (_) => TextEditingController());

  // Timer
  Timer? timer;

  void startTimer() {
    timer?.cancel();
    secondsLeft = 119;
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (secondsLeft > 0) {
        secondsLeft--;
      } else {
        t.cancel();
      }
      notifyListeners();
    });
  }

  void flickSignUpGlow() {
    signUpGlow = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 500), () {
      signUpGlow = false;
      notifyListeners();
    });
  }

  void disposeAll() {
    emailController.dispose();
    countryFieldController.dispose();
    countrySearchController.dispose();
    dobController.dispose();
    focusNodes.forEach((f) => f.dispose());
    codeControllers.forEach((c) => c.dispose());
    timer?.cancel();
  }
}
