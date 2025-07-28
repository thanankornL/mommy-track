import 'package:carebellmom/chatbot/message_ai.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import '../notification.dart';
import '../PersonalPage.dart';
import 'package:carebellmom/nursePages/chatbot_Nurse.dart';

class Chatbot_index_Nurse extends StatefulWidget {
  const Chatbot_index_Nurse({super.key});

  @override
  State<Chatbot_index_Nurse> createState() => _Chatbot_index_NurseState();
}

class _Chatbot_index_NurseState extends State<Chatbot_index_Nurse> {
  final TextEditingController _controller = TextEditingController();

  final List<Message> _message = [
    Message(text: 'Hi', isUser: true),
    Message(text: "Hello what's up", isUser: false),
    Message(text: 'Great are you ', isUser: true),
    Message(text: "I'm excellent", isUser: false),
  ];
  bool _isLoading = false;

  callGeminiModel() async {
    try {
      if (_controller.text.isNotEmpty) {
        setState(() {
          _message.add(Message(text: _controller.text, isUser: true));
          _isLoading = true;
        });
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // ✅ อย่าลืมแก้ชื่อโมเดลด้วย
        apiKey: dotenv.env["GOOGLE_API_KEY"]!,
      );

      final prompt = _controller.text.trim();
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _message.add(
          Message(text: response.text ?? "⚠️ ไม่สามารถตอบได้", isUser: false),
        );
        _isLoading = false;
      });

      _controller.clear();
    } catch (e) {
      print("Error : $e");
      setState(() {
        _message.add(Message(text: "❌ Error: ${e.toString()}", isUser: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 2,
        shadowColor: const Color.fromARGB(255, 221, 221, 221),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/chatbot/bot.png",
                  width: screenWidth * 0.09,
                ),

                SizedBox(width: 10),
                Text(
                  'Chatbot_GPT',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: screenHeight * 0.02,
                  ),
                ),
              ],
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _message.length,
              itemBuilder: (context, index) {
                final message = _message[index];
                return ListTile(
                  title: Align(
                    alignment:
                        message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: message.isUser ? Colors.blue : Colors.grey[300],
                        borderRadius:
                            message.isUser
                                ? BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                )
                                : BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          //input user
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 32,
              left: 16,
              right: 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Write your mesage.....",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: GestureDetector(
                      onTap: callGeminiModel,
                      child: Icon(Icons.send),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
