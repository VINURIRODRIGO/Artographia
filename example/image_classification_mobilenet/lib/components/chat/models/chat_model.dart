class Conversation {
  final String question;
  final String answer;

  Conversation(this.question, this.answer);

  factory Conversation.fromJson(Map json) => Conversation(
        json['question'],
        json['answer'],
      );
}