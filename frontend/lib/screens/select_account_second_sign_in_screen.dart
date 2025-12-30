import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_project/providers/font_size_provider.dart';
import '../providers/signup_data_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/footer_widgets.dart';

class SelectAccountSecondSignInScreen extends StatefulWidget {
  const SelectAccountSecondSignInScreen({super.key});

  @override
  State<SelectAccountSecondSignInScreen> createState() =>
      _SelectAccountSecondSignInScreenState();
}

class _SelectAccountSecondSignInScreenState
    extends State<SelectAccountSecondSignInScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image
                Center(
                  child: Image.asset(
                    'assets/images/egetyPerfectStar.png',
                    width: 111,
                    height: 126,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 2),

                // "Egety Trust"
                const Text(
                  'Egety Trust',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),

                const SizedBox(height: 10),

                // Description text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    'Step into a dynamic realm powered by \n decentralization, where true data \n ownership and assets belong to you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // "Select an Account"
                const Text(
                  'Select an Account',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),

                // add dynamic YY
                Container(
                  width: double.infinity,
                  height: 316,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [userCardAccount(context, userProvider)],
                  ),
                ),

                buildAddProfileButton(),

                const SizedBox(height: 30),

                FooterWidget(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget userCardAccount(BuildContext context, UserProvider userProvider) {
    final fontProvider = Provider.of<FontSizeProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: 312,
        height: 69,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00F0FF), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/sign-in');
          },
          child: Row(
            children: [
              // Profile Image
              Container(
                margin: const EdgeInsets.only(left: 11),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/image1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Texts Column (Name + EID)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userProvider.firstName}${userProvider.lastName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'EID: ${userProvider.eid}',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: fontProvider.getScaledSize(15),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAddProfileButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        CustomButton(
          text: 'Add New Profile',
          width: 200,
          height: 45,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          textColor: Colors.white,
          borderColor: const Color(0xFF00F0FF),
          backgroundColor: const Color(0xFF0B1320),
        ),

        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF0B1320)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
