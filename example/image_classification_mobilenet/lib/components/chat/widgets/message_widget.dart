import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_classification_mobilenet/components/chat/contants/colors.dart';
import 'package:clipboard/clipboard.dart';
import 'package:logger/logger.dart';

class MessageWidget extends StatefulWidget {
  final String text;
  final bool fromAi;

  const MessageWidget({Key? key, required this.text, this.fromAi = false})
      : super(key: key);

  @override
  _MessageWidgetState createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  final Logger logger = Logger();
  bool isCopied = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text == "") {
      return const CircularProgressIndicator();
    }
    return Align(
      alignment:
          widget.fromAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * .8),
            decoration: BoxDecoration(
                color: widget.fromAi
                    ? CustomColors.midGrey
                    : const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(8).copyWith(
                    bottomLeft: widget.fromAi ? const Radius.circular(0) : null,
                    bottomRight: !widget.fromAi ? const Radius.circular(0) : null)),
            margin: widget.fromAi
                ? const EdgeInsets.only(top: 0)
                : const EdgeInsets.only(top: 70),
            padding: const EdgeInsets.all(12),
            child: Text(widget.text),
          ),
          if (widget.fromAi) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: MediaQuery.of(context).size.width * .8,
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      FlutterClipboard.copy(widget.text).then((value) {
                        logger.d('copied text');
                        setState(() {
                          isCopied = true;
                        });
                        Timer(const Duration(seconds: 3), () {
                          setState(() {
                            isCopied = false;
                          });
                        });
                      });
                    },
                    child: Row(
                      children: [
                        if (!isCopied)
                          const Icon(Icons.copy_outlined,
                              size: 16, color: Colors.white),
                        if (!isCopied) const SizedBox(width: 10),
                        Text(
                          isCopied ? 'Copied' : 'Copy',
                          style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}
