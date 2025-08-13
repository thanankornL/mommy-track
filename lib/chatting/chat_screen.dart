import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:carebellmom/config.dart';

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String currentUserRole;
  final String chatPartner;
  final String chatPartnerName;
  final String chatPartnerRole;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.currentUserRole,
    required this.chatPartner,
    required this.chatPartnerName,
    required this.chatPartnerRole,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  Timer? _refreshTimer;
  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _markMessagesAsRead();
    
    // รีเฟรชข้อความทุก 3 วินาที
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _loadChatHistory(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_chat_history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user1': widget.currentUser,
          'user2': widget.chatPartner,
          'limit': 100
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['messages'] != null) {
          List<ChatMessage> newMessages = (data['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();
          
          setState(() {
            messages = newMessages;
            isLoading = false;
          });

          // เลื่อนไปที่ข้อความล่าสุดหากมีข้อความใหม่
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && newMessages.isNotEmpty) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          setState(() {
            messages = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || isSending) return;

    String messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/send_message'), // แก้ไข URL ให้ถูกต้อง
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': widget.currentUser,
          'receiver': widget.chatPartner,
          'message': messageText,
          'timestamp': DateTime.now().toIso8601String(),
          'senderRole': widget.currentUserRole,
        }),
      );

      if (response.statusCode == 201) {
        // โหลดข้อความใหม่
        await _loadChatHistory(showLoading: false);
      } else {
        // แสดงข้อผิดพลาด
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถส่งข้อความได้')),
          );
        }
        // คืนข้อความกลับไปในช่องพิมพ์
        _messageController.text = messageText;
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งข้อความ')),
        );
      }
      // คืนข้อความกลับไปในช่องพิมพ์
      _messageController.text = messageText;
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/mark_messages_read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': widget.chatPartner,
          'receiver': widget.currentUser,
        }),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.chatPartnerRole == 'nurse' 
                  ? Colors.blue[100] 
                  : Colors.pink[100],
              child: Icon(
                widget.chatPartnerRole == 'nurse' 
                    ? Icons.local_hospital 
                    : Icons.person,
                color: widget.chatPartnerRole == 'nurse' 
                    ? Colors.blue[700] 
                    : Colors.pink[700],
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatPartnerName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.chatPartnerRole == 'nurse' ? 'พยาบาล' : 'คนไข้',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // ส่วนแสดงข้อความ
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : Container(
                    color: Colors.grey[50],
                    child: messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'ยังไม่มีข้อความ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'เริ่มสนทนาโดยการส่งข้อความแรก',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.sender == widget.currentUser;
                              
                              return _buildMessageBubble(message, isMe);
                            },
                          ),
                  ),
          ),
          
          // ส่วนพิมพ์ข้อความ
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -1),
                  blurRadius: 5,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !isSending,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isSending ? Colors.grey : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: isSending 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white),
                      onPressed: isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.senderRole == 'nurse' 
                  ? Colors.blue[100] 
                  : Colors.pink[100],
              child: Icon(
                message.senderRole == 'nurse' 
                    ? Icons.local_hospital 
                    : Icons.person,
                size: 16,
                color: message.senderRole == 'nurse' 
                    ? Colors.blue[700] 
                    : Colors.pink[700],
              ),
            ),
            SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 5),
                      bottomRight: Radius.circular(isMe ? 5 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          if (isMe) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.currentUserRole == 'nurse' 
                  ? Colors.blue[100] 
                  : Colors.pink[100],
              child: Icon(
                widget.currentUserRole == 'nurse' 
                    ? Icons.local_hospital 
                    : Icons.person,
                size: 16,
                color: widget.currentUserRole == 'nurse' 
                    ? Colors.blue[700] 
                    : Colors.pink[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}

class ChatMessage {
  final String sender;
  final String receiver;
  final String message;
  final DateTime timestamp;
  final String senderRole;
  final bool isRead;

  ChatMessage({
    required this.sender,
    required this.receiver,
    required this.message,
    required this.timestamp,
    required this.senderRole,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] ?? '',
      receiver: json['receiver'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      senderRole: json['senderRole'] ?? '',
      isRead: json['isRead'] ?? false,
    );
  }
}