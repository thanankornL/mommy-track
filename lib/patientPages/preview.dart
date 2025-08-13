import 'package:carebellmom/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:matertino_radio/matertino_radio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'viewDetails.dart';

class PreviewState extends StatefulWidget {
  const PreviewState({super.key});

  @override
  State<PreviewState> createState() => _PreviewState();
}

class _PreviewState extends State<PreviewState> {
  final TextEditingController _childUsernameController =
      TextEditingController();
  final TextEditingController _childBirthdayController =
      TextEditingController();

  // This will store the DateTime value of the birthday
  DateTime? _childStoredBirthday;

  String motherName = '';
  String selectedGender = '';
  List<Map<String, dynamic>> lists = [
    {"title": "Male", "iconData": Icons.male_rounded, 'color': Colors.blue},
    {"title": "Female", "iconData": Icons.female_rounded, 'color': Colors.pink},
  ];
  String? selectedItem;

  @override
  void initState() {
    super.initState();
    getUsername();
  }

  Future<void> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    setState(() {
      motherName = username ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Child Name",
                          border: OutlineInputBorder(),
                        ),
                        controller: _childUsernameController,
                      ),
                      SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Child Birthday",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: _childBirthdayController,
                        readOnly: true,
                        onTap: () async {
                          BottomPicker.date(
                            pickerTitle: Text('Select Date'),
                            pickerTextStyle: TextStyle(fontSize: 20),
                            initialDateTime: DateTime.now(),
                            maxDateTime: DateTime.now(),
                            minDateTime: DateTime(1980, 1, 1),
                            onSubmit: (date) {
                              setState(() {
                                // Format and display the date as a string
                                _childBirthdayController.text =
                                    "${date.day}/${date.month}/${date.year}";

                                // Store the actual DateTime value
                                _childStoredBirthday = date;
                              });
                            },
                          ).show(context);
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: List.generate(lists.length, (index) {
                          String genderTitle = lists[index]['title'];
                          Color genderColor =
                              genderTitle == "Male" ? Colors.blue : Colors.pink;

                          return Expanded(
                            child: MatertinoRadioListTile(
                              value: genderTitle,
                              groupValue: selectedGender,
                              title: genderTitle,
                              titleStyle: TextStyle(fontSize: 18),
                              selectedRadioIconData: lists[index]['iconData'],
                              unselectedRadioIconData: lists[index]['iconData'],
                              borderColor: genderColor,
                              selectedRadioColor: genderColor,
                              tileColor: Colors.transparent,
                              onChanged: (val) {
                                setState(() {
                                  selectedGender = val!;
                                });
                              },
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 20),
                      Text('Mother: $motherName'),
                    ],
                  ),
                ),
              ),
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
                  ),
                  onPressed: () async {
                    if (_childStoredBirthday != null) {
                      final action = await updateAction(
                        _childUsernameController.text,
                        motherName,
                        _childStoredBirthday!,
                        selectedGender,
                      );

                      // Check if the response was successful
                      if (action != null) {
                        // Pop the current page
                        Navigator.pop(context);

                        // Navigate to the ViewDetails page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ViewDetails(), // Replace with your ViewDetails widget
                          ),
                        );
                      } else {
                        debugPrint(
                          'Failed to save data or no action returned.',
                        );
                      }
                    } else {
                      debugPrint('Please select a valid birthday.');
                    }
                  },

                  child: Text(
                    'Confirm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

Future<int?> updateAction(
  String child,
  String mother,
  DateTime date,
  String gender,
) async {
  final uri = Uri.parse('$baseUrl/api/create_baby_data');

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'child': child,
        'mother': mother,
        'birthday':
            date.toIso8601String(), // Convert DateTime to ISO 8601 string
        'action': 0,
        'gender': gender,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success']) {
        debugPrint("\x1B[33mUser details saved successfully!\x1B[0m");
        return response.statusCode; // This should be an int
      } else {
        debugPrint(
          "\x1B[33m⚠️ Server responded with an error: ${data['message']}\x1B[0m",
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
