import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_classification_mobilenet/pages/home_page.dart';
import 'package:image_classification_mobilenet/components/auth/login_or_register.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if (snapshot.hasData) {
            // Show alert when user logs in
            WidgetsBinding.instance!.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("ParkinSpiral!"),
                    content: const Text("To make the Learning Process sucess follow these steps 😊"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                         child: const Text(
                          "Close",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async{
                           launchUrl(Uri.parse('https://sway.cloud.microsoft/Db3LEyhXNoKEwjyQ?ref=Link'));
                        },
                        child: const Text(
                          "Let's Go",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  );
                },
              );
            });

            return HomePage();
          }

          // user is NOT logged in
          else {
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}
