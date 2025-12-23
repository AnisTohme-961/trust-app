import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_navigation_widget.dart';

class FreezeAccount extends StatefulWidget {
  const FreezeAccount({super.key});

  @override
  State<FreezeAccount> createState() => _FreezeAccountState();
}

class _FreezeAccountState extends State<FreezeAccount> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0B1320),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 186),
              // SVG Image
              SvgPicture.asset(
                'assets/images/frozenIcon.svg',
                width: 120,
                height: 120,
              ),

              const SizedBox(height: 24),
              // Text content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Text(
                  'Your account is frozen,\nunfreeze it to continue\nyour activity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 90),
              // Unfreeze Button
              CustomButton(
                text: 'Unfreeze',
                onTap: () {
                  // Add your unfreeze logic here
                  print('Unfreeze button tappe');
                },
                width: 106,
                height: 40,
                borderColor: const Color(0xFF00F0FF),
                textColor: Colors.white,
                backgroundColor: Colors.transparent,
                borderRadius: 10,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),

              const SizedBox(height: 90),
              // Custom Navigation Widget with Delete Account and Switch Account buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: CustomNavigationWidget(
                  // Left button: Delete Account
                  cancelText: 'Delete Account',
                  onCancel: () {
                    // Add your delete account logic here
                    print('Delete Account button tapped');
                  },
                  // Right button: Switch Account
                  nextText: 'Switch Account',
                  onNext: () {
                    // Add your switch account logic here
                    print('Switch Account button tapped');
                  },
                  // Styling for Delete Account button
                  cancelButtonWidth: 155,
                  cancelButtonHeight: 40,
                  cancelFontSize: 20,
                  cancelFontWeight: FontWeight.w600,
                  cancelTextColor: Colors.white,
                  cancelBorderColor: const Color(0xFF00F0FF),
                  cancelBackgroundColor: Colors.transparent,
                  cancelBorderRadius: 10,
                  // Styling for Switch Account button
                  nextButtonWidth: 162,
                  nextButtonHeight: 40,
                  nextFontSize: 20,
                  nextFontWeight: FontWeight.w600,
                  nextTextColor: Colors.white,
                  nextBorderColor: const Color(0xFF00F0FF),
                  nextBackgroundColor: Colors.transparent,
                  nextBorderRadius: 10,
                  // Line styling
                  lineHeight: 4,
                  lineRadius: 11,
                  spacing: 16,
                  startGradientColor: const Color(0xFF00F0FF),
                  endGradientColor: const Color(0xFF0B1320),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
