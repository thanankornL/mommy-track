import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'dart:developer';
import 'package:slide_action/slide_action.dart';

import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';


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
  final __usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 35),
              Row(
                mainAxisSize:
                    MainAxisSize
                        .min, // important: so the Row doesn't expand fully
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 26),
                  SizedBox(width: 8),
                  Text(
                    "เลือกผู้ใช้งาน",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
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
                    __usernameController.text =
                        user?.username ?? ''; // Update the controller text
                    log(user.toString());
                  });
                },
                compareFn: (a, b) => a.username == b.username,
                dropdownBuilder:
                    (context, selectedItem) => Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text(
                          selectedItem?.displayname ?? "Select user",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
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
              Row(
                mainAxisSize:
                    MainAxisSize
                        .min, // important: so the Row doesn't expand fully
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt, size: 26),
                  SizedBox(width: 8),
                  Text(
                    "แก้ไขข้อมูล",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _telephoneController,
                decoration: InputDecoration(
                  label: Row(
                    children: [
                      Icon(Icons.phone, size: 20),
                      SizedBox(width: 8),
                      Text("เบอร์มือถือ"),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  label: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text("ชื่อจริง"),
                    ],
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              Spacer(),
              _buildSlideAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideAction() {
    return SizedBox(
      width: 300,
      child: SlideAction(
        stretchThumb: true,
        trackBuilder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: const Center(
              child: Text("บันทึกข้อมูล", style: TextStyle(fontSize: 18)),
            ),
          );
        },
        thumbBuilder: (context, state) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: state.isPerformingAction ? Colors.grey : Color(0xffFFB26F),
              borderRadius: BorderRadius.circular(100),
            ),
            child:
                state.isPerformingAction
                    ? const CupertinoActivityIndicator(color: Color(0xffFFB26F))
                    : const Icon(Icons.edit, color: Colors.white),
          );
        },
        action: () async {
          final Map<String, dynamic> data = {
            'telephone': _telephoneController.text,
            'displayname': _displayNameController.text,
          };
          debugPrint(data.toString());
          final result = await editUser(__usernameController.text, data);
          debugPrint(result.toString());
          if (result != null) {
            showModalBottomSheet(
              context: context,
              clipBehavior: Clip.antiAlias,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              builder: (BuildContext context) {
                return GiffyBottomSheet.image(
                  Image.asset(
                    "assets/jk/1.gif",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  title: Text('ยืนยันเรียบร้อย', textAlign: TextAlign.center),
                  content: Text(
                    'ข้อมูลได้รับการอัปเดต',
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else {
            showModalBottomSheet(
              context: context,
              clipBehavior: Clip.antiAlias,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              builder: (BuildContext context) {
                return GiffyBottomSheet.image(
                  Image.asset(
                    "assets/jk/2.gif",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  title: Text('เกิดข้อผิดพลาด', textAlign: TextAlign.center),
                  content: Text(
                    'อัปเดตข้อมูลไม่สำเร็จ',
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Try Again'),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}

Future<int?> editUser(String username, Map<String, dynamic> data) async {
  final uri = Uri.parse('$baseUrl/api/edit_user_data');

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'role': "patient", 'data': data}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        return response.statusCode;
      } else {
        debugPrint(
          "⚠️ Server responded with an error: ${responseData['message']}",
        );
      }
    } else {
      debugPrint(
        "❌ Failed to fetch action. Status code: ${response.statusCode}",
      );
    }
  } catch (e) {
    debugPrint("🚨 Error while fetching action: $e");
  }

  return null;
}