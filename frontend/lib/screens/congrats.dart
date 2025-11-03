import 'package:flutter/material.dart';
import 'package:flutter_project/main.dart';
import 'package:flutter_project/screens/register.dart';
import 'package:flutter_project/widgets/footer_widgets.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';

class RegisterLivePage extends StatefulWidget {
  const RegisterLivePage({super.key});

  @override
  State<RegisterLivePage> createState() => _RegisterLivePageState();
}

class _RegisterLivePageState extends State<RegisterLivePage> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320), // background color
      body: SafeArea(
        child: Center(
          child: Container(
            width: 430,
            height: 932,
            child: Stack(
              children: [
                // "Congratulations! You’re In!"
                Positioned(
                  top: 100,
                  left: 20,
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      "Congratulations! You’re In!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // "Welcome to Egety Trust"
                Positioned(
                  top: 158,
                  left: 73,
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      "Welcome to Egety Trust",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Gradient bar with "Joe Doe"
                Positioned(
                  top: 218,
                  left: 1,
                  child: Container(
                    width: 428,
                    height: 80, // enough height for name + EID row
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color.fromRGBO(0, 240, 255, 0),
                          const Color.fromRGBO(0, 240, 255, 0.8),
                          const Color.fromRGBO(0, 240, 255, 0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Joe Doe
                        Text(
                          "${userProvider.firstName} ${userProvider.lastName}",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            color: Color(0xFF0B1320),
                          ),
                        ),

                        // EID + Icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "EID: ${userProvider.eid}",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 25,
                                color: Color(0xFF0B1320),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 18,
                              height: 18,
                              child: Image.asset(
                                'assets/images/DoubleSquare.png', // replace with your PNG
                                width: 18,
                                height: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Description text under the gradient container
                Positioned(
                  top: 318,
                  left: 8,
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      "Your EID is your unique ID across \n all apps. Save it safely you’ll \n need it to access everything",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 470,
                  left: 139,
                  child: Container(
                    width: 153,
                    height: 200,
                    decoration: BoxDecoration(
                      // Optional if you want background color behind the image
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // rounded corners (optional)
                    ),
                    child: Image.asset(
                      'assets/images/Unlocked animstion.png', // replace with your image path
                      fit:
                          BoxFit.contain, // keeps aspect ratio inside container
                    ),
                  ),
                ),
                // Gradient line under the image
                Positioned(
                  top: 734,
                  left: 28,
                  child: Container(
                    width: 91,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight, // 270deg
                        end: Alignment.centerLeft,
                        colors: [Color(0xFF00F0FF), Color(0xFF0B1320)],
                      ),
                    ),
                  ),
                ),
                // "Get Started" button
                Positioned(
                  top: 716,
                  left: 135,
                  child: CustomButton(
                    text: "Get Started",
                    width: 161,
                    height: 40,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    textColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    borderColor: const Color(0xFF00F0FF),
                    borderRadius: 10,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegisterPage(), // replace with your HomePage
                        ),
                      );
                    },
                  ),
                ),

                // Right-side gradient line next to the button
                Positioned(
                  top: 734,
                  left: 312,
                  child: Container(
                    width: 90,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        begin: Alignment.centerRight, // 270deg
                        end: Alignment.centerLeft,
                        colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                      ),
                    ),
                  ),
                ),
                Positioned(bottom: 0, left: 0, right: 0, child: FooterWidget()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
