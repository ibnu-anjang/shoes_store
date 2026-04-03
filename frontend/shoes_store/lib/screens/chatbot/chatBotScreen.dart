import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, String>> messages = [];

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "text": controller.text,
      });
      messages.add({
        "role": "bot",
        "text": "Halo! Saya Sneakerhead   ",
      });
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Icon(Icons.person, color: Colors.black54),
          ),
        ),
        title: const Text(
          "Sneakerhead",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg["role"] == "user";

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isUser)
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black12,
                            child: Icon(Icons.person,
                                size: 16, color: Colors.black54),
                          ),

                        if (!isUser) const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          constraints:
                              const BoxConstraints(maxWidth: 250),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.black
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            msg["text"]!,
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (messages.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 80,
                          color: Colors.black.withOpacity(0.2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Apa yang ingin ditanyakan?",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding:
             const EdgeInsets.fromLTRB(10, 8, 10, 25),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Tulis pertanyaan...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon:
                        const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}