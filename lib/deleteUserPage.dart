import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:slide_action/slide_action.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// --------- User Model ----------
class User {
  final String id;
  final String username;
  final String displayname;
  final String? telephone;
  final String? edc;
  final String? ga;
  final String? lmp;
  final String? us;
  final int? action;
  final String? lastNotify;
  final DateTime? childDate;

  User({
    required this.id,
    required this.username,
    required this.displayname,
    this.telephone,
    this.edc,
    this.ga,
    this.lmp,
    this.us,
    this.action,
    this.lastNotify,
    this.childDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print(json.keys);
    final idField = json['_id'];
    final String id =
        (idField is Map && idField.containsKey('\$oid'))
            ? idField['\$oid']
            : (idField is String)
            ? idField
            : '';

    return User(
      id: id,
      username: json['username'] ?? '',
      displayname: json['display_name'] ?? '',
      telephone: json['telephone'],
      edc: json['EDC'],
      ga: json['GA'],
      lmp: json['LMP'],
      us: json['US'],
      action: json['action'],
      lastNotify: json['lastNotify'],
      childDate:
          json['childDate'] != null && json['childDate'] is Map
              ? DateTime.tryParse(json['childDate']['\$date'])
              : null,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, displayname: $displayname, EDC: $edc, telephone: $telephone, GA: $ga, LMP: $lmp, US: $us, action: $action, lastNotify: $lastNotify, childDate: $childDate)';
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

class deleteUserPage extends StatefulWidget {
  const deleteUserPage({super.key});

  @override
  _deleteUserPageState createState() => _deleteUserPageState();
}

class _deleteUserPageState extends State<deleteUserPage> {
  User? selectedUser;
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _edcController = TextEditingController();
  final _GAController = TextEditingController();
  final _LMPController = TextEditingController();
  final _USController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _ActionController = TextEditingController();
  final _lastNotifyController = TextEditingController();

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
        body: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween, // Push content to the top and bottom
          children: [
            SingleChildScrollView(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  DropdownSearch<User>(
                    selectedItem: selectedUser,
                    items: (String filter, LoadProps? props) async {
                      final users = await fetchUsers();
                      if (filter.isEmpty) return users;
                      return users
                          .where(
                            (u) => u.displayname.toLowerCase().contains(
                              filter.toLowerCase(),
                            ),
                          )
                          .toList();
                    },
                    itemAsString: (User u) => u.displayname,
                    onChanged: (User? user) async {
                      if (user == null) return;

                      setState(() {
                        selectedUser = user;
                        _displayNameController.text = user.displayname;
                        _usernameController.text = user.username;
                        _edcController.text = user.edc ?? '';
                        _GAController.text = user.ga ?? '';
                        _LMPController.text = user.lmp ?? '';
                        _USController.text = user.us ?? '';
                        _telephoneController.text = user.telephone ?? '';
                        _lastNotifyController.text = user.lastNotify ?? '';
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
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      label: Row(
                        children: [
                          Icon(Icons.person_remove, size: 20),
                          SizedBox(width: 8),
                          Text("Username"),
                        ],
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 16.0,
              ), // Add space at the bottom
              child: _buildSlideAction(), // Button will be placed at the bottom
            ),
          ],
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
              child: Text("ลบข้อมูลผู้ใช้", style: TextStyle(fontSize: 18)),
            ),
          );
        },
        thumbBuilder: (context, state) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: state.isPerformingAction ? Colors.grey : Colors.red,
              borderRadius: BorderRadius.circular(100),
            ),
            child:
                state.isPerformingAction
                    ? const CupertinoActivityIndicator(color: Colors.red)
                    : const Icon(Icons.delete, color: Colors.white),
          );
        },
        action: () async {
          final result = await deleteUser(_usernameController.text);
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

Future<int?> deleteUser(String username) async {
  final uri = Uri.parse('$baseUrl/api/delete_user');

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'role': 'patient'}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return response.statusCode; // This should be an int
      } else {
        debugPrint("⚠️ Server responded with an error: ${data['message']}");
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
