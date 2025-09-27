import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? '';

  Future<String> sendMessage(String prompt) async {
    final response = await http.post(
      Uri.parse("$backendUrl/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "model": "claude-3-haiku-20240307",
        "max_tokens": 500,
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["content"]?[0]?["text"] ?? "No response";
    } else {
      throw Exception("Backend error: ${response.body}");
    }
  }
}
