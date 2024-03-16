import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_classification_mobilenet/components/chat/contants/colors.dart';
import 'package:image_classification_mobilenet/components/chat/models/chat_model.dart';
import 'package:image_classification_mobilenet/components/chat/widgets/example_widget.dart';
import 'package:http/http.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:logger/logger.dart';
import '../../pages/home_page.dart';
import 'widgets/chat_list_view.dart';
import 'widgets/chat_text_field.dart';
import 'package:emoji_regex/emoji_regex.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _HomePageState();
}

class _HomePageState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  List<Conversation> conversations = [];
  bool get isConversationStarted => conversations.isNotEmpty;
  final Logger logger = Logger();
  final emoji = emojiRegex();
  String url = "http://10.0.2.2:8000/get-response";
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
        appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('ArtoBot Tutor'), 
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
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: SizedBox(
               height: MediaQuery.of(context).size.height * .95,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isConversationStarted) ...[
                      const SizedBox(height:  12),
                      Text(
                        "Learn today, save lives tomorrow! 😊",
                        style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 0, 0)),
                        textAlign: TextAlign.center,
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Examples",
                                style: textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 15),
                              const ExampleWidget(
                                  text:
                                      "“What is  Parkinson's disease?”"),
                              const ExampleWidget(
                                  text:
                                      "“What are the ways of detecting Parkinson's disease at eraly stage?”"),
                              const ExampleWidget(
                                  text:
                                      "“What is Micrographia?”"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 90),
                    ] else
                      Expanded(
                          child: ChatListView(conversations: conversations)),
                          
                    ChatTextField(
                      controller: controller,
                      onSubmitted: (question) async {
                        controller.clear();
                        FocusScope.of(context).unfocus();
                        conversations.add(Conversation(question!, ""));
                        setState(() {});
                        try {
                          final response = await post(
                            Uri.parse(url),
                            body: jsonEncode({"text": question}),
                            headers: {"Content-Type": "application/json"},
                          );
                          if (response.statusCode == 200) {
                            String result =
                                jsonDecode(response.body)['response'];
                            result = result
                                .replaceAll(RegExp(r'\[\^\d+\]'),
                                    '') // Remove , , , etc.
                                .replaceAll(
                                    RegExp(r'\*\*'), ''); // Remove ** **
                            // Remove emojis
                         
                            result = emoji.allMatches(result)
                                .fold(result, (prev, element) {
                              return prev.replaceAll(element.group(0) as Pattern, '');
                            });
                            conversations.last = Conversation(
                              conversations.last.question,
                              html2md.convert(result),
                            );
                            setState(() {});
                          } else {
                            logger.d(
                                'Request failed with status: ${response.statusCode}.');
                          }
                        } catch (e) {
                          logger.d('Request failed with error: $e.');
                        }
                      },
                    ),
                    isConversationStarted ? const SizedBox(height: 15) : const SizedBox(height: 90), // Conditional height
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
