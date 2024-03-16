// import 'dart:io';
import 'package:image_classification_mobilenet/components/chat/chat_page.dart';
// import 'package:image_classification_mobilenet/components/upload/image_display_page.dart';
// import 'package:image_classification_mobilenet/components/upload/image_picker.dart';
import 'package:image_classification_mobilenet/pages/auth_page.dart';
import 'package:image_classification_mobilenet/pages/notes_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_classification_mobilenet/pages/upload_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!.email!.split('@').first;
  void navigateToGallery(BuildContext context) async {
        // Navigate to ImageDisplayScreen with the picked image
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>const UploadScren(),
          ),
    );
  }

  // sign user out method
  void showUserOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                // Navigate to profile screen
                // You can implement this based on your navigation setup
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                // Sign out the user
                widget.signUserOut();
                // Redirect to AuthPage after signing out
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) =>
                      false, // This will remove all routes until AuthPage
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  title: Text(user,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white)),
                  subtitle: Text('Good Morning',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white54)),
                  trailing: GestureDetector(
                    onTap: () {
                      showUserOptions(context); // Show user options popup
                    },
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('images/person.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 30)
              ],
            ),
          ),
          Container(
            color: Theme.of(context).primaryColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
              decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 224, 224, 224),
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(200))),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 40,
                mainAxisSpacing: 30,
                children: [
                  itemDashboard(
                      'ArtoBot Tutor', CupertinoIcons.book_fill, Colors.brown),
                  itemDashboard('Documnetation', CupertinoIcons.collections,
                      Colors.deepOrange),
                  itemDashboard(
                      'ParkinSpiral', CupertinoIcons.add_circled, Colors.teal),
                  itemDashboard(
                      'Notes', CupertinoIcons.question_circle, Colors.blue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget itemDashboard(String title, IconData iconData, Color background) {
    if (title == 'ParkinSpiral') {
      return GestureDetector(
        onTap: () => navigateToGallery(context),
        child: _buildDashboardItem(title, iconData, background),
      );
    } else if (title == 'Notes') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotesScreen()),
          );
        },
        child: _buildDashboardItem(title, iconData, background),
      );
    } else if (title == 'ArtoBot Tutor') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        child: _buildDashboardItem(title, iconData, background),
      );
    } else {
      return _buildDashboardItem(title, iconData, background);
    }
  }

  Widget _buildDashboardItem(
      String title, IconData iconData, Color background) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 5),
              color: Theme.of(context).primaryColor.withOpacity(.2),
              spreadRadius: 2,
              blurRadius: 5,
            )
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white)),
          const SizedBox(height: 8),
           Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 10), // Adjusting font size to 10
        )
        ],
      ),
    );
  }
}
