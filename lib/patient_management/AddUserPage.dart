import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../config.dart'; // Import the config file
import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';

class AddUser extends StatefulWidget {
  const AddUser({super.key});

  @override
  _AddUserState createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  final TextEditingController _lmpDateController = TextEditingController();
  final TextEditingController _edcDateController = TextEditingController();
  final TextEditingController _gaController = TextEditingController();

  final TextEditingController _gaUSController = TextEditingController();
  final TextEditingController _edcUSController = TextEditingController();
  final TextEditingController _ultrasoundDateController =
      TextEditingController();
  final TextEditingController _ultrasoundGAController = TextEditingController();

  final TextEditingController _gaManualController = TextEditingController();
  final TextEditingController _edcManualController = TextEditingController();
  final TextEditingController _daysManualController = TextEditingController();
  final TextEditingController _lmpAprxManualController =
      TextEditingController();

  final TextEditingController _userNationalIDController =
      TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _telephoneNumberController =
      TextEditingController();
  String _selectedOption = ""; // Default selected option

  void _calculateEDCAndGA() {
    if (_lmpDateController.text.isNotEmpty) {
      try {
        final lmpDateParts = _lmpDateController.text.split('/');
        final lmpDate = DateTime(
          int.parse(lmpDateParts[2]),
          int.parse(lmpDateParts[1]),
          int.parse(lmpDateParts[0]),
        );

        final edcDate = lmpDate.add(
          Duration(days: 280),
        ); // Add 280 days (40 weeks)
        final currentDate = DateTime.now();
        final gaDays = currentDate.difference(lmpDate).inDays;
        final gaWeeks = gaDays ~/ 7;
        final gaRemainingDays = gaDays % 7;

        setState(() {
          _edcDateController.text =
              "${edcDate.day}/${edcDate.month}/${edcDate.year}";
          _gaController.text = "$gaWeeks weeks $gaRemainingDays days";
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Invalid LMP date format")));
      }
    }
  }

  int convertGAtodays(String gaText) {
    debugPrint("GA Text: $gaText");
    final gaMatch = RegExp(
      r'^\s*(\d+)\s*weeks?\s*(\d+)\s*days?\s*$',
      caseSensitive: false,
    ).firstMatch(gaText);
    if (gaMatch == null) {
      return 0; // Invalid GA format
    }
    final weeks = int.tryParse(gaMatch.group(1)!);
    final days = int.tryParse(gaMatch.group(2)!);
    print('weeks: $weeks, days: $days, gaText: $gaText');
    if (weeks == null || days == null || days < 0 || days > 6) {
      return 0; // Invalid GA values
    }
    return (weeks * 7) + days;
  }

  void _calculateFromUltrasound() {
    final usDateText = _ultrasoundDateController.text.trim();
    final gaText = _ultrasoundGAController.text.trim();

    try {
      final usDateParts = usDateText.split('/');
      final usDate = DateTime(
        int.parse(usDateParts[2]),
        int.parse(usDateParts[1]),
        int.parse(usDateParts[0]),
      );

      final gaMatch = RegExp(r'^\s*(\d+)\s*\+\s*(\d+)\s*$').firstMatch(gaText);

      if (gaMatch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid GA format. Use like 8+2")),
        );
        return;
      }

      final weeks = int.tryParse(gaMatch.group(1)!);
      final days = int.tryParse(gaMatch.group(2)!);

      if (weeks == null || days == null || days < 0 || days > 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid GA values. Days should be 0–6")),
        );
        return;
      }

      final totalDays = (weeks * 7) + days;
      final lmpDate = usDate.subtract(Duration(days: totalDays));
      final edcDate = lmpDate.add(Duration(days: 280));

      setState(() {
        _gaUSController.text = "$weeks weeks $days days";
        _edcUSController.text =
            "${edcDate.day}/${edcDate.month}/${edcDate.year}";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing ultrasound data")),
      );
    }
  }

  void _calculateManual() {
    final gaText = _gaManualController.text.trim();

    final weeks = int.tryParse(gaText);

    if (weeks == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid GA values. Days should be 0–6")),
      );
      return;
    }

    final totalDays = (weeks * 7);

    setState(() {
      _daysManualController.text = totalDays.toString(); // Save total days
    });
    _calculateEDCFromGA(totalDays); // Calculate EDC based on GA
    _calculateLMPFromGA(totalDays); // Calculate LMP based on GA
  }

  void _calculateLMPFromGA(int totalDays) {
    final currentDate = DateTime.now();
    final lmpDate = currentDate.subtract(Duration(days: totalDays));
    setState(() {
      _lmpAprxManualController.text =
          "${lmpDate.day}/${lmpDate.month}/${lmpDate.year}";
    });
  }

  void _calculateEDCFromGA(int totalDays) {
    final currentDate = DateTime.now();
    final lmpDate = currentDate.subtract(Duration(days: totalDays));
    final edcDate = lmpDate.add(Duration(days: 280));

    setState(() {
      _edcManualController.text =
          "${edcDate.day}/${edcDate.month}/${edcDate.year}";
    });
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "กรอกหมายเลขบัตรประชาชน",
                border: OutlineInputBorder(),
              ),
              controller: _userNationalIDController,
              obscureText: false,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "กรอกรหัสผ่าน",
                border: OutlineInputBorder(),
              ),
              controller: _userPasswordController,
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "กรออกชื่อแะนามสกุล",
                border: OutlineInputBorder(),
              ),
              controller: _userNameController,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "หมายเลขโทรศัพท์",
                border: OutlineInputBorder(),
              ),
              controller: _telephoneNumberController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 16),
            CustomRadioButton<String>(
              spacing: MediaQuery.of(context).size.width * 0.02,
              elevation: 0,
              absoluteZeroSpacing: false,
              unSelectedColor: Theme.of(context).canvasColor,
              buttonLables: ['LMP', 'US', 'Manual'],
              buttonValues: ["LMP", "Ultrasound", "Manual"],
              buttonTextStyle: ButtonTextStyle(
                selectedColor: Colors.white,
                unSelectedColor: Colors.black,
                textStyle: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
              radioButtonValue: (value) {
                _selectedOption = value;
                setState(() {
                  if (_selectedOption == "LMP") {
                    _lmpDateController.clear();
                    _edcDateController.clear();
                    _gaController.clear();
                  } else if (_selectedOption == "Ultrasound") {
                    _ultrasoundDateController.clear();
                    _ultrasoundGAController.clear();
                    _gaUSController.clear();
                    _edcUSController.clear();
                  } else if (_selectedOption == "Manual") {
                    _gaManualController.clear();
                  }
                });
              },
              radius: 5,
              unSelectedBorderColor: Colors.black,
              selectedBorderColor: Colors.white,
              selectedColor: Colors.blueAccent,
              width: MediaQuery.of(context).size.width * 0.27,
              autoWidth: false,
              enableButtonWrap: true,
              wrapAlignment: WrapAlignment.center,
            ),
            SizedBox(height: 16),
            if (_selectedOption == "LMP")
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lmpDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "LMP Date",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                _lmpDateController.text =
                                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                              });
                              _calculateEDCAndGA(); // Automatically calculate EDC and GA
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _lmpDateController.clear();
                            _edcDateController.clear();
                            _gaController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _edcDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "EDC Date",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _gaController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Gestational Age (GA)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            if (_selectedOption == "Ultrasound")
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ultrasoundDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Ultrasound Date",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                _ultrasoundDateController.text =
                                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                              });
                              _calculateFromUltrasound();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _ultrasoundDateController.clear();
                            _ultrasoundGAController.clear();
                            _gaUSController.clear();
                            _edcUSController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _ultrasoundGAController,
                    decoration: InputDecoration(
                      labelText: "Gestational Age (e.g. 8+2)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (value) => _calculateFromUltrasound(),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _gaUSController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Gestational Age (GA)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _edcUSController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "EDC Date",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            if (_selectedOption == "Manual")
              Column(
                children: [
                  TextField(
                    controller: _gaManualController,
                    decoration: InputDecoration(
                      labelText: "Approximately Gestational Age (weeks)",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _calculateManual(); // Calculate GA and EDC when text changes
                      setState(() {
                        _gaManualController.text = value;
                      });
                    },
                    keyboardType: TextInputType.text,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _daysManualController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "DAYS",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _edcManualController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "EDC Date",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _lmpAprxManualController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Approximately LMP Date",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () async {
                    final userData = {
                      'username': _userNationalIDController.text,
                      'password': _userPasswordController.text,
                      'name': _userNameController.text,
                      'role': 'patient',
                      'telephone': _telephoneNumberController.text,
                    };

                    if (_selectedOption == "LMP") {
                      userData['EDC'] = _edcDateController.text;
                      userData['LMP'] = _lmpDateController.text;
                      userData['GA'] =
                          convertGAtodays(_gaController.text).toString();
                    } else if (_selectedOption == "Ultrasound") {
                      userData['EDC'] = _edcUSController.text;
                      userData['US'] = _ultrasoundDateController.text;
                      userData['GA'] =
                          convertGAtodays(_gaUSController.text).toString();
                    } else if (_selectedOption == "Manual") {
                      _calculateManual(); // Ensure manual calculation is done
                      userData['GA'] =
                          _daysManualController.text; // Save total days
                      userData['EDC'] = _edcManualController.text;
                      userData['LMP'] = _lmpAprxManualController.text;
                    }

                    try {
                      final response = await http.post(
                        Uri.parse(
                          '$baseUrl/api/register',
                        ), // Replace with your API URL
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(userData),
                      );

                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("User details saved successfully!"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to save user details"),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("An error occurred: $e")),
                      );
                    }
                  },
                  child: Text(
                    'Save User',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
