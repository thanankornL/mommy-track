import 'package:carebellmom/chatbot/message_ai.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Chatbot_index_patient extends StatefulWidget {
  const Chatbot_index_patient({super.key});

  @override
  State<Chatbot_index_patient> createState() => _Chatbot_index_patientState();
}

class _Chatbot_index_patientState extends State<Chatbot_index_patient> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Message> _message = [
    Message(text: 'Hi', isUser: true),
    Message(text: "Hello what's up", isUser: false),
    Message(text: 'Great are you ', isUser: true),
    Message(text: "I'm excellent", isUser: false),
  ];
  
  bool _isLoading = false;

  // ฟังก์ชันเลื่อนไปข้อความล่าสุด
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  callGeminiModel() async {
    if (_controller.text.trim().isEmpty) return;
    
    try {
      final userMessage = _controller.text.trim();
      
      setState(() {
        _message.add(Message(text: userMessage, isUser: true));
        _isLoading = true;
      });
      
      _controller.clear();
      _scrollToBottom();

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env["GOOGLE_API_KEY"]!,
      );

      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content);

      setState(() {
        _message.add(
          Message(text: response.text ?? "⚠️ ไม่สามารถตอบได้", isUser: false),
        );
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print("Error : $e");
      setState(() {
        _message.add(Message(text: "❌ Error: ${e.toString()}", isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Row(
          children: [
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: const Color(0xFF2D3748),
                    fontSize: screenHeight * 0.022,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'พร้อมให้บริการ',
                  style: TextStyle(
                    color: const Color(0xFF718096),
                    fontSize: screenHeight * 0.014,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _message.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // แสดงการพิมพ์ของ AI
                if (index == _message.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                
                final message = _message[index];
                return _buildMessageBubble(message, screenWidth);
              },
            ),
          ),
          _buildInputField(screenWidth),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: 
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(17.5),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 5),
                  bottomRight: Radius.circular(message.isUser ? 5 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : const Color(0xFF2D3748),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(17.5),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(17.5),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI กำลังพิมพ์',
                  style: TextStyle(
                    color: const Color(0xFF718096),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF667eea),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(double screenWidth) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => callGeminiModel(), // เพิ่มการกด Enter
              decoration: const InputDecoration(
                hintText: "พิมพ์ข้อความของคุณ...",
                hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20, 
                  vertical: 15
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _isLoading ? null : callGeminiModel,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: _isLoading 
                      ? null 
                      : const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _isLoading ? const Color(0xFFE2E8F0) : null,
                  borderRadius: BorderRadius.circular(22.5),
                  boxShadow: [
                    if (!_isLoading)
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isLoading ? const Color(0xFFA0AEC0) : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}