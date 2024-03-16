import 'package:flutter/material.dart';

class ChatTextField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String?) onSubmitted;

  const ChatTextField(
      {super.key, required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color:   const Color.fromARGB(255, 234, 224, 253),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color.fromARGB(208, 199, 171, 252), width: .8)),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Flexible(
            child: TextField(
              controller: controller,
              cursorColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(border: InputBorder.none,filled: true, fillColor: Color.fromARGB(255, 234, 224, 253)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: IconButton(
              onPressed: () {
                onSubmitted(controller.text);
              },
              style: IconButton.styleFrom(
                  backgroundColor: const Color.fromARGB(208, 199, 171, 252),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4))),
              icon: const Icon(Icons.send_outlined, color: Color.fromARGB(255, 0, 0, 0),),
            ),
          )
        ],
      ),
    );
  }
}