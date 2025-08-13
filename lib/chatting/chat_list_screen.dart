import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';
import 'package:carebellmom/config.dart';
import 'package:flutter/services.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 🔹 กำหนดค่าจำลองก่อน
  const username = 'username';
  const userRole = 'senderRole'; // หรือ 'nurse'
  const displayName = 'display_name';

  // 🔹 ส่งค่าเข้า ChatListScreen อย่างถูกต้อง
  runApp(
    MaterialApp(
      home: ChatListScreen(
        username: username,
        userRole: userRole,
        displayName: displayName,
      ),
    ),
  );
}

class ChatListScreen extends StatefulWidget {
  final String username;
  final String userRole;
  final String displayName;

  const ChatListScreen({
    super.key,
    required this.username,
    required this.userRole,
    required this.displayName,
  });

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatContact> contacts = [];
  List<User> allUsers = [];
  bool isLoading = true;
  bool showNewChatDialog = false;

  @override
  void initState() {
    super.initState();
    _loadChatContacts();
    _loadAllUsers();
  }

  Future<void> _loadChatContacts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_chat_contacts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'role': widget.userRole,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          List<ChatContact> loadedContacts = (data['contacts'] as List)
              .map((contact) => ChatContact.fromJson(contact))
              .toList();

          setState(() {
            contacts = loadedContacts;
            isLoading = false;
          });
        } else {
          setState(() {
            contacts = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          contacts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chat contacts: $e');
      setState(() {
        contacts = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      String endpoint = widget.userRole == 'nurse' 
          ? '/api/get_all_patients' 
          : '/api/get_all_nurses';
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          List<User> users = [];
          String key = widget.userRole == 'nurse' ? 'patients' : 'nurses';
          
          users = (data[key] as List)
              .map((user) => User.fromJson(user))
              .toList();

          setState(() {
            allUsers = users;
          });
        }
      }
    } catch (e) {
      print('Error loading all users: $e');
    }
  }

  void _startNewChat(User user) {
    Navigator.pop(context); // ปิด dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.username,
          currentUserRole: widget.userRole,
          chatPartner: user.username,
          chatPartnerName: user.displayName,
          chatPartnerRole: widget.userRole == 'nurse' ? 'patient' : 'nurse',
        ),
      ),
    ).then((_) {
      // รีเฟรชรายชื่อแชทเมื่อกลับมา
      _loadChatContacts();
    });
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.userRole == 'nurse' 
                ? 'เลือกคนไข้ที่ต้องการแชท' 
                : 'เลือกพยาบาลที่ต้องการแชท'
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: allUsers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: allUsers.length,
                    itemBuilder: (context, index) {
                      final user = allUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.userRole == 'nurse' 
                              ? Colors.pink[100] 
                              : Colors.blue[100],
                          child: Icon(
                            widget.userRole == 'nurse' 
                                ? Icons.person 
                                : Icons.local_hospital,
                            color: widget.userRole == 'nurse' 
                                ? Colors.pink[700] 
                                : Colors.blue[700],
                          ),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.username),
                        onTap: () => _startNewChat(user),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อความ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChatContacts,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : contacts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChatContacts,
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _buildChatItem(contact);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: Colors.blue,
        child: Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีการสนทนา',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'กดปุ่ม + เพื่อเริ่มแชทใหม่',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatContact contact) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: widget.username,
              currentUserRole: widget.userRole,
              chatPartner: contact.username,
              chatPartnerName: contact.displayName,
              chatPartnerRole: contact.role,
            ),
          ),
        ).then((_) {
          // รีเฟรชรายชื่อแชทเมื่อกลับมา
          _loadChatContacts();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // รูปโปรไฟล์
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: contact.role == 'nurse' 
                      ? Colors.blue[100] 
                      : Colors.pink[100],
                  child: Icon(
                    contact.role == 'nurse' 
                        ? Icons.local_hospital 
                        : Icons.person,
                    color: contact.role == 'nurse' 
                        ? Colors.blue[700] 
                        : Colors.pink[700],
                    size: 24,
                  ),
                ),
                // แสดงจุดแดงถ้ามีข้อความยังไม่อ่าน
                if (contact.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        contact.unreadCount > 99 
                            ? '99+' 
                            : contact.unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(width: 12),
            
            // ข้อมูลแชท
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        contact.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: contact.unreadCount > 0 
                              ? FontWeight.bold 
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatChatTime(contact.lastTimestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.lastMessage.isEmpty ? 'ไม่มีข้อความ' : contact.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: contact.unreadCount > 0 
                                ? Colors.black87 
                                : Colors.grey[600],
                            fontWeight: contact.unreadCount > 0 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      SizedBox(width: 8),
                      
                      // แสดงไอคอนบทบาท
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: contact.role == 'nurse' 
                              ? Colors.blue[50] 
                              : Colors.pink[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          contact.role == 'nurse' ? 'พยาบาล' : 'คนไข้',
                          style: TextStyle(
                            fontSize: 10,
                            color: contact.role == 'nurse' 
                                ? Colors.blue[700] 
                                : Colors.pink[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatChatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชม.';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาที';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}

// Model classes
class ChatContact {
  final String username;
  final String displayName;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;
  final String role;

  ChatContact({
    required this.username,
    required this.displayName,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
    required this.role,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastTimestamp: json['lastTimestamp'] != null 
          ? DateTime.parse(json['lastTimestamp']) 
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      role: json['role'] ?? '',
    );
  }
}

class User {
  final String username;
  final String displayName;
  final String? telephone;

  User({
    required this.username,
    required this.displayName,
    this.telephone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      telephone: json['telephone'],
    );
  }
}