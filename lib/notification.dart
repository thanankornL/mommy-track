import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<String> getSessionUsername() async {
    final username = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getString('username') ?? 'user',
    );
    return username; // Replace with actual session username retrieval
  }

  Future<void> fetchNotifications() async {
    final String username =
        await getSessionUsername(); // Fetch username from session

    final Uri url = Uri.parse('$baseUrl/api/notifications?username=$username');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          notifications = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return ListView(
      children: [
        SizedBox(height: 20),
        Card(
          margin: EdgeInsets.all(5.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          color: Colors.white,
          child: SizedBox(
            height: screenHeight * 0.8,
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(Icons.notifications),
                          title: Text(item['title'] ?? 'No title'),
                          subtitle: Text(item['body'] ?? 'No message'),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}

// --------- User Model ----------
class User {
  final String id;
  final String username;
  final String displayname;

  User({required this.id, required this.username, required this.displayname});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      displayname: json['display_name'],
    );
  }
}

// --------- Fetch Users ----------
Future<List<User>> fetchUsers() async {
  final response = await http.get(Uri.parse('$baseUrl/api/users'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((userJson) => User.fromJson(userJson)).toList();
  } else {
    throw Exception('Failed to load users');
  }
}

// --------- UI ----------
class sendNotification extends StatefulWidget {
  const sendNotification({super.key});

  @override
  State<sendNotification> createState() => _SendNotificationState();
}

class _SendNotificationState extends State<sendNotification> {
  User? selectedUser;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  void sendNotification() async {
    if (selectedUser == null ||
        _titleController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please complete all fields")));
      return;
    }
    final notificationData = {
      'username': selectedUser!.username,
      'title': _titleController.text,
      'body': _messageController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    // Here you can send the notification via HTTP POST using selectedUser.username, etc.
    //print("Sending notification to: ${selectedUser!.username}");
    //print("Title: ${_titleController.text}");
    //print("Message: ${_messageController.text}");
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/send_notification',
        ), // Replace with your API URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User details saved successfully!")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save user details")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending notification")));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Notification sent successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send Notification")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownSearch<User>(
              selectedItem: selectedUser,
              items: (String filter, LoadProps? props) async {
                final users = await fetchUsers(); // your API call
                if (filter.isEmpty) return users;
                // Optional: basic local filtering
                return users
                    .where(
                      (u) => u.displayname.toLowerCase().contains(
                        filter.toLowerCase(),
                      ),
                    )
                    .toList();
              },
              itemAsString: (User u) => u.displayname,
              onChanged: (User? user) {
                setState(() => selectedUser = user);
              },
              compareFn: (a, b) => a.username == b.username,
              dropdownBuilder:
                  (context, selectedItem) => Text(
                    selectedItem?.displayname ?? "Select user",
                    style: TextStyle(fontSize: 16),
                  ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search user...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Notification Title",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: "Notification Message",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    sendNotification();
                  },
                  child: Text(
                    'Send',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
