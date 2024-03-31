import 'package:flutter/material.dart';
import 'package:image_classification_mobilenet/components/chat/contants/colors.dart';
import '../../pages/home_page.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Instructions'),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: CustomColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          StepWidget(
            stepNumber: 1,
            title: 'Step 1',
            description: 'This is the first step.', key: Key('step_1'),
          ),
          StepWidget(
            stepNumber: 2,
            title: 'Step 2',
            description: 'This is the second step.', key: Key('step_2'),
          ),
      
        ],
      ),
    );
  }
}

class StepWidget extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;

  const StepWidget({
    required Key key,
    required this.stepNumber,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        'STEP $stepNumber: $title',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(description),
    );
  }
}
