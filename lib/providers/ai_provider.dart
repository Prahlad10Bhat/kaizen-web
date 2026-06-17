import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

class AiNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    final hour = DateTime.now().hour;
    String greeting = "Hello";
    if (hour >= 0 && hour < 4) {
      greeting = "Good night";
    } else if (hour >= 4 && hour < 12) {
      greeting = "Good morning";
    } else if (hour >= 12 && hour < 16) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }

    return [
      ChatMessage(
        text: "$greeting! I'm Kaizen, your personal operating layer. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearMessages() {
    final hour = DateTime.now().hour;
    String greeting = "Hello";
    if (hour >= 0 && hour < 4) {
      greeting = "Good night";
    } else if (hour >= 4 && hour < 12) {
      greeting = "Good morning";
    } else if (hour >= 12 && hour < 16) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }

    state = [
      ChatMessage(
        text: "$greeting! I'm Kaizen, your personal operating layer. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
  }
}

final aiProvider = NotifierProvider<AiNotifier, List<ChatMessage>>(() {
  return AiNotifier();
});
