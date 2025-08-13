import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carebellmom/config.dart';

class ChatService {
  // ส่งข้อความ
  static Future<bool> sendMessage({
    required String sender,
    required String receiver,
    required String message,
    required String senderRole,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': sender,
          'receiver': receiver,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'senderRole': senderRole,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error sending message: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // ดึงประวัติแชท
  static Future<List<ChatMessage>?> getChatHistory({
    required String user1,
    required String user2,
    int limit = 50,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_chat_history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user1': user1,
          'user2': user2,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['messages'] != null) {
          return (data['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();
        }
      } else {
        print('Error getting chat history: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error getting chat history: $e');
      return null;
    }
  }

  // ดึงรายชื่อผู้ติดต่อ
  static Future<List<ChatContact>?> getChatContacts({
    required String username,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_chat_contacts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['contacts'] != null) {
          return (data['contacts'] as List)
              .map((contact) => ChatContact.fromJson(contact))
              .toList();
        }
      } else {
        print('Error getting chat contacts: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error getting chat contacts: $e');
      return null;
    }
  }

  // อัพเดทสถานะข้อความว่าอ่านแล้ว
  static Future<bool> markMessagesAsRead({
    required String sender,
    required String receiver,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mark_messages_read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': sender,
          'receiver': receiver,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error marking messages as read: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  // ดึงรายชื่อคนไข้ทั้งหมด (สำหรับพยาบาล)
  static Future<List<User>?> getAllPatients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_all_patients'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['patients'] != null) {
          return (data['patients'] as List)
              .map((user) => User.fromJson(user))
              .toList();
        }
      } else {
        print('Error getting all patients: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error getting all patients: $e');
      return null;
    }
  }

  // ดึงรายชื่อพยาบาลทั้งหมด (สำหรับคนไข้)
  static Future<List<User>?> getAllNurses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_all_nurses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['nurses'] != null) {
          return (data['nurses'] as List)
              .map((user) => User.fromJson(user))
              .toList();
        }
      } else {
        print('Error getting all nurses: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('Error getting all nurses: $e');
      return null;
    }
  }

  // เช็คสถานะการเชื่อมต่อกับเซิร์ฟเวอร์
  static Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Server connection error: $e');
      return false;
    }
  }
}

// Model classes
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

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'receiver': receiver,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'senderRole': senderRole,
      'isRead': isRead,
    };
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'displayName': displayName,
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp.toIso8601String(),
      'unreadCount': unreadCount,
      'role': role,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'display_name': displayName,
      'telephone': telephone,
    };
  }
}