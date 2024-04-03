import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText, required int fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: SizedBox(
        height: 55, // Adjusted height to make it smaller
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            fillColor: const Color.fromARGB(255, 240, 226, 238),
            filled: true,
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Custom TextField Demo'),
      ),
      body: Center(
        child: CustomTextField(
          controller: TextEditingController(),
          hintText: 'Enter your text',
          obscureText: false, fontSize: 12,
        ),
      ),
    ),
  ));
}
