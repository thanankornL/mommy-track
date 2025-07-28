import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'dart:developer';

// --------- User Model ----------
class User {
  final String id;
  final String username;
  final String displayname;
  final String? telephone; // Optional field
  User({
    required this.id,
    required this.username,
    required this.displayname,
    required this.telephone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      displayname: json['display_name'],
      telephone: json['telephone'] ?? '', // Handle optional field
    );
  }
}

Future<List<User>> fetchUsers() async {
  final response = await http.get(Uri.parse('$baseUrl/api/users'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((userJson) => User.fromJson(userJson)).toList();
  } else {
    throw Exception('Failed to load users');
  }
}

class editUserPage extends StatefulWidget {
  const editUserPage({super.key});
  @override
  _editUserPageState createState() => _editUserPageState();
}

class _editUserPageState extends State<editUserPage> {
  User? selectedUser;
  final _telephoneController = TextEditingController();
  final _displayNameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit User")),
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
                setState(() {
                  selectedUser = user;
                  _telephoneController.text =
                      user?.telephone ?? ''; // Update the controller text
                  _displayNameController.text =
                      user?.displayname ?? ''; // Update the controller text
                  log(user.toString());
                });
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
              controller: _telephoneController,
              decoration: InputDecoration(
                labelText: "Telephone : ${_telephoneController.text}",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: "Display Name : ${_displayNameController.text}",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
