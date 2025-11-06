import 'package:flutter/widgets.dart';
import '../screens/signup.dart';
import '../screens/sign_in_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/register_pin.dart';
import '../screens/register_pattern_screen.dart';
import '../screens/forgot_eid_screen.dart';
import '../screens/select_account_second_sign_in_screen.dart';
import '../screens/sign_in_second_time_screen.dart';
import '../screens/sign_in_pin_screen.dart';
import '../screens/sign_in_pattern_screen.dart';
import '../screens/coming_soon_screen.dart';

Map<String, WidgetBuilder> appRoutes() {
  return {
    '/sign-up': (_) => const SignUpPage(),
    '/sign-in': (_) => const SignInPage(),
    '/forgot-password': (_) => const ForgotPasswordScreen(),
    '/register-pin': (_) =>
        const ResponsiveRegisterPinScreen(title: "Register Pin"),
    '/register-pattern': (_) => const ResponsiveRegisterPatternScreen(),
    '/forgot-eid': (_) => const ForgotEidPage(),
    '/select-account-second-signin': (_) =>
        const SelectAccountSecondSignInScreen(),
    '/sign-in-second-screen': (_) => const SignInSecondTimeScreen(),
    '/sign-in-register-pin': (_) => const SignInRegisterPinScreen(),
    '/sign-in-pattern': (_) => const SignInPatternScreen(),
    '/coming-soon': (_) => const ComingSoonPage(),
  };
}
