import 'dart:io';
import 'package:artographia/pages/image_display_page.dart';
import 'package:artographia/pages/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  ImagePickerHandler pickerHandler = ImagePickerHandler(
    context: context,
    onImagePicked: (File? pickedImage) {
      // Navigate to ImageDisplayScreen with the picked image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageDisplayScreen(pickedImage: pickedImage),
        ),
      );
    },
  );
  pickerHandler.showPicker();
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
                  title: Text(user, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white
                  )),
                  subtitle: Text('Good Morning', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white54
                  )),
                  trailing: const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/user.JPG'),
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
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(200)
                )
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 40,
                mainAxisSpacing: 30,
                children: [            
                  itemDashboard('AI Chat', CupertinoIcons.chat_bubble_2, Colors.brown),
                  itemDashboard('Documnetation', CupertinoIcons.collections, Colors.deepOrange),
                  itemDashboard('Upload', CupertinoIcons.add_circled, Colors.teal),
                  itemDashboard('Notes', CupertinoIcons.question_circle, Colors.blue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20)
        ],
      ),
    );
  }
  Widget itemDashboard(String title, IconData iconData, Color background) {
  if (title == 'Upload') {
    return GestureDetector(
      onTap: () => navigateToGallery(context),
      child: _buildDashboardItem(title, iconData, background),
    );
  } else {
    return _buildDashboardItem(title, iconData, background);
  }
}

Widget _buildDashboardItem(String title, IconData iconData, Color background) {
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
      ]
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: Colors.white)
        ),
        const SizedBox(height: 8),
        Text(title.toUpperCase(), style: Theme.of(context).textTheme.titleMedium)
      ],
    ),
  );
}

}