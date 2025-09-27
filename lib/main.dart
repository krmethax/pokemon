import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  String _selectedProvider = "openai";
  String _selectedModel = "gpt-4o-mini";

  final Map<String, List<String>> providerModels = {
    "openai": ["gpt-4o-mini", "gpt-4", "gpt-3.5-turbo"],
    "anthropic": ["claude-3-haiku-20240307", "claude-3-opus-20240229"]
  };

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    try {
      final reply = await sendMessage(text);
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
        _isTyping = false;
      });
    }
  }

  Future<String> sendMessage(String prompt) async {
    if (_selectedProvider == "openai") {
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": _selectedModel,
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 500,
        }),
      );
      final data = jsonDecode(response.body);
      if (data["choices"] != null && data["choices"].isNotEmpty) {
        return data["choices"][0]["message"]["content"];
      } else if (data["error"] != null) {
        return "API Error: ${data["error"]["message"]}";
      }
      return "No response";
    }

    if (_selectedProvider == "anthropic") {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {
          "x-api-key": apiKey,
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01"
        },
        body: jsonEncode({
          "model": _selectedModel,
          "max_tokens": 500,
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt}
              ]
            }
          ]
        }),
      );
      final data = jsonDecode(response.body);
      if (data["content"] != null && data["content"].isNotEmpty) {
        return data["content"][0]["text"];
      } else if (data["error"] != null) {
        return "API Error: ${data["error"]["message"]}";
      }
      return "No response";
    }

    return "Invalid provider";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar: เลือก Provider + Model
          Container(
            width: 220,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Model Selector",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Provider dropdown
                DropdownButton<String>(
                  value: _selectedProvider,
                  isExpanded: true,
                  items: providerModels.keys
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedProvider = v!;
                      _selectedModel = providerModels[v]!.first;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Model dropdown
                DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  items: providerModels[_selectedProvider]!
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedModel = v!;
                    });
                  },
                ),
              ],
            ),
          ),

          // Main Chat Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("AI Chat",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.smart_toy, color: Colors.deepPurple),
                    ],
                  ),
                ),

                // Messages area
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.all(20),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (_, idx) =>
                          _messages[_messages.length - 1 - idx],
                    ),
                  ),
                ),

                if (_isTyping)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 8),
                      Text("AI is typing...")
                    ]),
                  ),

                // Input box
                _buildComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: "Type a message...",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _handleSubmitted(_controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.all(14),
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isUser ? Colors.deepPurple : Colors.grey.shade300;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: alignment,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15)),
        ),
      ),
    );
  }
}
