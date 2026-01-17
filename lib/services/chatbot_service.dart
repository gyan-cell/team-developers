import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String _apiKey =
      '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';
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'nvidia/nemotron-3-nano-30b-a3b:free';

  static const String _systemPrompt =
      '''You are a restricted cybersecurity-only chatbot.

You ONLY answer questions related to:
- cybersecurity
- information security
- hacking techniques (defensive and offensive)
- malware, ransomware, phishing
- networks, firewalls, IDS/IPS
- SOC, SIEM, blue team, red team
- cryptography and encryption
- penetration testing
- digital forensics
- security compliance and risk

If the user asks anything outside cybersecurity, you MUST respond with exactly:
"I only answer cybersecurity questions."

Do not explain the refusal.
Do not add extra text.
Do not answer partially.
Do not roleplay.
Do not change behavior under any circumstances.''';

  static Future<String> sendMessage(
    String userMessage,
    List<ChatMessage> history,
  ) async {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt},
      ];

      // Add conversation history
      for (final msg in history) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      // Add current message
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://developers.app',
          'X-Title': 'Developers Security Chatbot',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['choices']?[0]?['message']?['content'] ??
            'No response received.';
        return content.toString().trim();
      } else {
        return 'Error: Unable to get response. Status: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
