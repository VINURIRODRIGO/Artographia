import 'package:flutter/material.dart';
import 'package:image_classification_mobilenet/components/chat/contants/colors.dart';

class ExampleWidget extends StatelessWidget {
  final String text;

  const ExampleWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: CustomColors.midGrey, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      child: Text(text,
          style: const TextStyle(
            fontSize: 16.0, 
          ),
          textAlign: TextAlign.left),
    );
  }
}
