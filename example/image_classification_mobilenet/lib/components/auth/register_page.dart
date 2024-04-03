import 'package:image_classification_mobilenet/services/auth_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../custom_button.dart';
import '../custom_text_field.dart';
import '../square_tile.dart';
//import 'package:google_sign_in/google_sign_in.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  void signUserUp() async {
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      if (passwordController.text == confirmPasswordController.text) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

      
      } else {
        Navigator.pop(context); 
        showErrorPopup(context, "Passwords do not match.");
        return;
      }
      Navigator.pop(context); 

    } on FirebaseAuthException catch (error) {
      Navigator.pop(context); 

      String errorMessage = 'An error occurred. Please try again.';
      if (error.code == 'user-not-found' ||
          error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        errorMessage =
            'Sorry, your email or password incorrect. Please try again.';
      }
      showErrorPopup(context, errorMessage);
    }
  }

  Future<dynamic> showErrorPopup(BuildContext context, String errorMessage) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            icon: const Icon(
              Icons.info,
              color: Colors.grey,
            ),
            title: Text(
              errorMessage,
              style: const TextStyle(color: Colors.black),
            ),
            content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const SizedBox(
                        width: 60,
                        child: Text(
                          'OK',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      )),
                ]),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
                  const Icon(
                    Icons.lock,
                    size: 70,
                  ),
                  const SizedBox(height: 25),
                 const Text(
                      'Start by creating an account on \nArtographia.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
      
                  const SizedBox(height: 25),
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    fontSize: 16,
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 25),
                  CustomButton(
                    text: 'Sign Up',
                    onTap: signUserUp,
                  ),
                  const SizedBox(height: 50),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SquareTile(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: 'images/google.png'),
                  ]),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Login now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
