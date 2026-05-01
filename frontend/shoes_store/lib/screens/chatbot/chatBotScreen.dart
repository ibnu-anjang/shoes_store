import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoes_store/services/authService.dart';

class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, String>> messages = [
    {"role": "bot", "text": "Yoo! Gua SoleMate. Ada yang bisa gua bantu soal nyari sepatu idaman lo?"}
  ];
  bool isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final userMessage = controller.text;
    setState(() {
      messages.add({
        "role": "user",
        "text": userMessage,
      });
      isLoading = true;
    });
    controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse("${AuthService.baseUrl}/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add({
            "role": "bot",
            "text": data["reply"],
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "bot",
          "text": "Sori bro, koneksi lagi bapuk atau gua lagi mikir kepanjangan nih. Coba ketik lagi ya!",
        });
      });
      _scrollToBottom();
    } finally {
      setState(() {
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("SoleMate AI", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: Navigator.canPop(context) 
          ? IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context))
          : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text("SoleMate sedang mengetik...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
                  );
                }

                final msg = messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.black : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(msg["text"]!, style: TextStyle(color: isUser ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Tulis pertanyaan...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: sendMessage),
                ),
              ],
            ),
            ),  // Container
          ),  // SafeArea
        ],
      ),
    );
  }
}