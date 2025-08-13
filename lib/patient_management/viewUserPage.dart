import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

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

// --------- Baby Model ----------
class Baby {
  final String id;
  final String child;
  final String mother;
  final String birthday;
  final String? action;
  final String? gender;

  Baby({
    required this.id,
    required this.child,
    required this.mother,
    required this.birthday,
    this.action,
    this.gender,
  });

  factory Baby.fromJson(Map<String, dynamic> json) {
    print(json.keys);
    final idField = json['_id'];
    final String id =
        (idField is Map && idField.containsKey('\$oid'))
            ? idField['\$oid']
            : (idField is String)
            ? idField
            : '';

    // แปลง birthday ให้รองรับทั้งแบบ Map และ String
    String birthdayStr = '';
    if (json['birthday'] != null) {
      if (json['birthday'] is Map && json['birthday'].containsKey('\$date')) {
        birthdayStr = json['birthday']['\$date'];
      } else if (json['birthday'] is String) {
        birthdayStr = json['birthday'];
      }
    }

    return Baby(
      id: id,
      child: json['child'] ?? '',
      mother: json['mother'] ?? '',
      action: json['action']?.toString(),
      gender: json['gender'],
      birthday: birthdayStr,
    );
  }

  @override
  String toString() {
    return 'Baby(id: $id, child: $child, mother: $mother, birthday: $birthday, action: $action, gender: $gender)';
  }
}

Future<Baby?> fetchBabyByMother(String motherId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/get_baby_data'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mother': motherId}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['success']) {
      return Baby.fromJson(data['data']);
    } else {
      print("Baby not found: ${data['message']}");
      return null;
    }
  } else {
    throw Exception("Failed to fetch baby data");
  }
}

class viewUserPage extends StatefulWidget {
  const viewUserPage({super.key});

  @override
  _viewUserPageState createState() => _viewUserPageState();
}

class _viewUserPageState extends State<viewUserPage> {
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

  final _childController = TextEditingController();
  final _motherController = TextEditingController();
  final _childActionController = TextEditingController();
  final _childGenderController = TextEditingController();

  String convertDaysToWeeksAndDays(String inputDays) {
    int days = int.parse(inputDays);
    int weeks = days ~/ 7;
    int remainingDays = days % 7;
    return '$weeks สัปดาห์ $remainingDays วัน';
  }

  bool _isChild = false;
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
        appBar: AppBar(title: Text('ดูรายละเอียดของคุณแม่'),),
        body: SingleChildScrollView(
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

                  final baby =
                      (user.action.toString() == "9")
                          ? await fetchBabyByMother(user.username)
                          : null;

                  // Async function to set action text
                  Future<void> setActionText(String username) async {
                    String actionMessage = await comparedMotherAction(username);
                    _ActionController.text = actionMessage;
                  }

                  await setActionText(user.username.toString());

                  setState(() {
                    selectedUser = user;
                    _displayNameController.text = user.displayname;
                    _usernameController.text = user.username;
                    _edcController.text = user.edc ?? '';
                    _GAController.text =
                        (user.ga != null && user.ga!.isNotEmpty)
                            ? convertDaysToWeeksAndDays(user.ga!)
                            : '';

                    _LMPController.text = user.lmp ?? '';
                    _USController.text = user.us ?? '';
                    _telephoneController.text = user.telephone ?? '';
                    _lastNotifyController.text = user.lastNotify ?? '';

                    _isChild = user.action.toString() == "9";

                    if (_isChild && baby != null) {
                      _childController.text = baby.child;
                      _motherController.text = baby.mother;
                      _childActionController.text = baby.action ?? '';
                      _childGenderController.text = baby.gender ?? '';
                    } else {
                      _childController.clear();
                      _motherController.clear();
                      _childActionController.clear();
                      _childGenderController.clear();
                    }
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

              SizedBox(height: 20),
              Row(
                mainAxisSize:
                    MainAxisSize
                        .min, // important: so the Row doesn't expand fully
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 26),
                  SizedBox(width: 8),
                  Text(
                    "ข้อมูลผู้ใช้งาน",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Column(
                children: [
                  // Always show these
                  _buildTextField(_usernameController, "Username"),
                  _buildTextField(_displayNameController, "ชื่อจริง"),

                  // Only show if not null or empty
                  if ((_edcController.text).isNotEmpty)
                    _buildTextField(_edcController, "EDC"),

                  if ((_GAController.text).isNotEmpty)
                    _buildTextField(_GAController, "GA"),

                  if ((_LMPController.text).isNotEmpty)
                    _buildTextField(_LMPController, "LMP"),

                  if ((_USController.text).isNotEmpty)
                    _buildTextField(_USController, "Ultrasound"),

                  if ((_telephoneController.text).isNotEmpty)
                    _buildTextField(_telephoneController, "เบอร์มือถือ"),

                  if ((_ActionController.text).isNotEmpty)
                    _buildTextField(_ActionController, "แอ็คชั่น"),

                  if ((_lastNotifyController.text).isNotEmpty)
                    _buildTextField(_lastNotifyController, "การแจ้งเตือน"),
                ],
              ),
              if (_isChild) ...[
                SizedBox(height: 20),
                Row(
                  mainAxisSize:
                      MainAxisSize
                          .min, // important: so the Row doesn't expand fully
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.baby_changing_station, size: 26),
                    SizedBox(width: 8),
                    Text(
                      "ข้อมูลเด็ก",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _buildTextField(_childController, "ชื่อของเด็ก"),
                _buildTextField(_motherController, "Mother ID"),
                if (_childActionController.text.isNotEmpty)
                  _buildTextField(_childActionController, "แอ็คชั่น"),
                if (_childGenderController.text.isNotEmpty)
                  _buildTextField(_childGenderController, "เพศ"),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        readOnly: true,
      ),
    );
  }
}

Future<String> comparedMotherAction(String motherId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/getAction?username=$motherId'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['success']) {
      String messages = '';
      final action = data['action'];

      print(action.runtimeType);

      if (action is int) {
        int action0 = action;

        switch (action0) {
          case 0:
            messages = "การแจ้งเตือนครั้งที่ 1";
          case 1:
            messages = "การแจ้งเตือนครั้งที่ 2";
          case 2:
            messages = "การแจ้งเตือนครั้งที่ 3";
          case 3:
            messages = "การแจ้งเตือนครั้งที่ 4";
          case 4:
            messages = "การแจ้งเตือนครั้งที่ 5";
          case 5:
            messages = "การแจ้งเตือนครั้งที่ 6";
          case 6:
            messages = "การแจ้งเตือนครั้งที่ 7";
          case 7:
            messages = "การแจ้งเตือนครั้งที่ 8";
          case 9:
            messages = "คลอดแล้ว";
        }
      }

      return messages;
    } else {
      print("Action not found: ${data['message']}");
      return '';
    }
  } else {
    throw Exception("Failed to fetch action data");
  }
}